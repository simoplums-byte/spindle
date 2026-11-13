import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var panel: NSPanel?
    private var statusItem: NSStatusItem?
    private var statusMenuItem: NSMenuItem?
    private var discMenu: NSMenu?
    private var controlItems: [NSMenuItem] = []
    private var lastIconStatus: PlaybackStatus = .unknown
    private let rotation = RotationModel()
    private let monitor = PlaybackMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        makePanel()
        makeStatusItem()
        startPlaybackDetection()
    }

    private func startPlaybackDetection() {
        monitor.onStatusChange = { [weak self] status in
            self?.rotation.setPlaying(status == .playing)
        }
        monitor.start()
    }

    // MARK: 悬浮窗

    private func makePanel() {
        let size = Token.windowSize
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: size, height: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true            // 交给窗口系统画投影，才能落在窗口边界之外
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true

        panel.contentView = makeHostingView()

        // 跟随鼠标所在的那块屏幕，而不是「焦点屏」——多显示器下焦点常在另一块上
        let pointer = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main
        if let screen {
            let visible = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: visible.maxX - size - 40,
                y: visible.maxY - size - 60
            ))
        }
        panel.orderFrontRegardless()
        self.panel = panel
    }

    // MARK: 菜单栏

    private func makeStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = StatusIcon.make(status: .unknown)
            button.toolTip = "Spindle"
        }

        let menu = NSMenu()
        let statusLine = NSMenuItem(title: "检测中…", action: nil, keyEquivalent: "")
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        statusMenuItem = statusLine

        for (title, action) in [
            ("上一曲", #selector(controlPrevious)),
            ("播放 / 暂停", #selector(controlToggle)),
            ("下一曲", #selector(controlNext))
        ] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            item.isEnabled = false
            menu.addItem(item)
            controlItems.append(item)
        }

        let rescan = NSMenuItem(title: "重新采样", action: #selector(rescan), keyEquivalent: "r")
        rescan.target = self
        menu.addItem(rescan)

        let skinsItem = NSMenuItem(title: "皮肤", action: nil, keyEquivalent: "")
        let skinsMenu = NSMenu()
        for skin in SkinID.allCases {
            let item = NSMenuItem(title: skin.displayName, action: #selector(selectSkin), keyEquivalent: "")
            item.target = self
            item.representedObject = skin.rawValue
            if skin == Token.activeSkin { item.state = .on }
            skinsMenu.addItem(item)
        }
        skinsItem.submenu = skinsMenu
        menu.addItem(skinsItem)

        let discsItem = NSMenuItem(title: "碟面", action: nil, keyEquivalent: "")
        let discsMenu = NSMenu()
        discsItem.submenu = discsMenu
        menu.addItem(discsItem)
        discMenu = discsMenu

        let iconsItem = NSMenuItem(title: "菜单栏图标", action: nil, keyEquivalent: "")
        let iconsMenu = NSMenu()
        for style in StatusIconStyle.allCases {
            let item = NSMenuItem(title: style.displayName, action: #selector(selectIconStyle), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            if style == StatusIcon.activeStyle { item.state = .on }
            iconsMenu.addItem(item)
        }
        iconsItem.submenu = iconsMenu
        menu.addItem(iconsItem)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "退出 Spindle", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
        refreshDiscMenu()
        startStatusMenuRefresh()
    }

    private func startStatusMenuRefresh() {
        let t = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshStatusMenu() }
        }
        RunLoop.main.add(t, forMode: .common)
    }

    // MARK: 控制（唯一允许写播放器的地方，且只能由用户点击触发）

    private func makeHostingView() -> DraggableHostingView<RootView> {
        let host = DraggableHostingView(rootView: RootView(rotation: rotation, monitor: monitor))
        host.onKeyCommand = { [weak self] command in
            self?.handleCommand(command)
        }
        return host
    }

    /// 三个按键 + 菜单栏三项都走这里。非 Apple Music 工况直接返回，什么都不发生。
    private func handleCommand(_ command: PlaybackCommand) {
        guard monitor.nowPlaying.source == .music else { return }
        MusicController.perform(command) { [weak self] in
            self?.monitor.refreshNow()
        }
    }

    @objc private func controlPrevious() { handleCommand(.previous) }
    @objc private func controlToggle() { handleCommand(.toggle) }
    @objc private func controlNext() { handleCommand(.next) }

    @objc private func selectIconStyle(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let style = StatusIconStyle(rawValue: raw) else { return }
        StatusIcon.activeStyle = style
        statusItem?.button?.image = StatusIcon.make(status: monitor.nowPlaying.status)
        sender.menu?.items.forEach { $0.state = ($0.representedObject as? String) == raw ? .on : .off }
    }

    private func refreshStatusMenu() {
        let state = monitor.nowPlaying
        let label: String
        switch state.status {
        case .playing: label = "播放中"
        case .paused: label = "已暂停"
        case .idle: label = "待机"
        case .unknown: label = "检测中…"
        }
        statusMenuItem?.title = "\(label) · \(state.lcdLine)"

        let controlsAvailable = state.source == .music && MusicController.isMusicRunning
        for item in controlItems where item.isEnabled != controlsAvailable {
            item.isEnabled = controlsAvailable
        }

        if state.status != lastIconStatus {
            lastIconStatus = state.status
            statusItem?.button?.image = StatusIcon.make(status: state.status)
        }
        refreshDiscMenu()
    }

    /// 「碟面」子菜单：`albumArt` 只在当前曲目拿得到封面时出现，勾选跟着实际生效的样式。
    private func refreshDiscMenu() {
        guard let menu = discMenu else { return }
        let artwork = monitor.nowPlaying.artwork
        let wanted = (artwork == nil ? [] : [DiscStyle.albumArt]) + DiscStyle.materials
        let current = menu.items.compactMap { $0.representedObject as? String }

        if current != wanted.map(\.rawValue) {
            menu.removeAllItems()
            for style in wanted {
                let item = NSMenuItem(title: style.displayName, action: #selector(selectDisc), keyEquivalent: "")
                item.target = self
                item.representedObject = style.rawValue
                menu.addItem(item)
            }
        }

        let effective = DiscToken.effective(for: artwork)
        for item in menu.items {
            guard let raw = item.representedObject as? String,
                  let style = DiscStyle(rawValue: raw) else { continue }
            item.state = style == effective ? .on : .off
        }
    }

    @objc private func selectSkin(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let skin = SkinID(rawValue: raw) else { return }
        Token.activeSkin = skin
        reloadContent()
        sender.menu?.items.forEach { $0.state = ($0.representedObject as? String) == raw ? .on : .off }
    }

    @objc private func selectDisc(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let disc = DiscStyle(rawValue: raw) else { return }
        DiscToken.select(disc)
        reloadContent()
        refreshDiscMenu()
    }

    /// 皮肤与碟面都是全局静态值，SwiftUI 不会自己重绘，重建一次宿主视图即可
    private func reloadContent() {
        panel?.contentView = makeHostingView()
        panel?.orderFrontRegardless()
    }

    @objc private func rescan() {
        monitor.stop()
        monitor.start()
        panel?.orderFrontRegardless()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - 渲染模式

@MainActor
func renderPrototype(to path: String, skin: SkinID = Token.activeSkin, artwork: NSImage? = nil) {
    _ = NSApplication.shared
    Token.activeSkin = skin
    let model = RotationModel()
    model.setPlaying(true)
    var state = NowPlaying()
    state.status = .playing
    state.source = .netease
    state.artwork = artwork
    let renderer = ImageRenderer(content: RenderSheet(model: model, state: state))
    renderer.scale = 2
    guard let cgImage = renderer.cgImage else {
        FileHandle.standardError.write("render failed\n".data(using: .utf8)!)
        exit(1)
    }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write("png encode failed\n".data(using: .utf8)!)
        exit(1)
    }
    do {
        try data.write(to: URL(fileURLWithPath: path))
        print("rendered \(path) \(cgImage.width)x\(cgImage.height) skin=\(skin.rawValue)")
    } catch {
        FileHandle.standardError.write("write failed: \(error)\n".data(using: .utf8)!)
        exit(1)
    }
}

/// 一次把全部皮肤渲染成 PNG，供对比挑选。
@MainActor
func renderAllSkins(to directory: String) {
    for skin in SkinID.allCases {
        let path = (directory as NSString).appendingPathComponent("\(skin.rawValue)@2x.png")
        renderPrototype(to: path, skin: skin)
    }
}

/// 一次把全部自有碟面渲染成 PNG，供对比挑选。`albumArt` 依赖运行时封面，不参与。
@MainActor
func renderAllDiscs(to directory: String) {
    for disc in DiscStyle.materials {
        DiscToken.select(disc)
        let path = (directory as NSString).appendingPathComponent("disc-\(disc.rawValue)@2x.png")
        renderPrototype(to: path)
    }
}

// MARK: - 入口

let arguments = CommandLine.arguments

MainActor.assumeIsolated {
    if let skinsIndex = arguments.firstIndex(of: "--render-skins") {
        let dir = arguments.count > skinsIndex + 1
            ? arguments[skinsIndex + 1]
            : "."
        renderAllSkins(to: dir)
        exit(0)
    }

    if let discIndex = arguments.firstIndex(of: "--disc"),
       arguments.count > discIndex + 1,
       let disc = DiscStyle(rawValue: arguments[discIndex + 1]) {
        DiscToken.select(disc)
    }

    if let controlIndex = arguments.firstIndex(of: "--control") {
        let raw = arguments.count > controlIndex + 1 ? arguments[controlIndex + 1] : ""
        guard let command = PlaybackCommand(rawValue: raw) else {
            FileHandle.standardError.write("usage: --control previous|toggle|next\n".data(using: .utf8)!)
            exit(2)
        }
        let ok = MusicController.execute(command)
        print(ok ? "ok \(command.rawValue)" : "failed \(command.rawValue)")
        exit(ok ? 0 : 1)
    }

    if arguments.contains("--status") {
        let monitor = PlaybackMonitor()
        for _ in 0..<4 {
            // 不用 start()：它装的是 NSTimer，在 CLI 里跑 RunLoop 会撞上 actor 断言。
            monitor.refreshNow()
            RunLoop.main.run(until: Date().addingTimeInterval(1))
            let snapshot = monitor.debugSnapshot()
            print("\(snapshot.0) \(snapshot.1.rawValue) | \(snapshot.2)")
        }
        exit(0)
    }

    if let iconsIndex = arguments.firstIndex(of: "--render-icons") {
        let path = arguments.count > iconsIndex + 1
            ? arguments[iconsIndex + 1]
            : "status-icons.png"
        StatusIconBoard.render(to: path)
        exit(0)
    }

    if let schemeIndex = arguments.firstIndex(of: "--icon-scheme"),
       arguments.count > schemeIndex + 1,
       let scheme = AppIconScheme(rawValue: arguments[schemeIndex + 1]) {
        AppIconRenderer.scheme = scheme
    }

    if let appIconIndex = arguments.firstIndex(of: "--render-app-icon") {
        let dir = arguments.count > appIconIndex + 1
            ? arguments[appIconIndex + 1]
            : "."
        AppIconRenderer.writeIconset(to: dir)
        exit(0)
    }

    if let appIconPreviewsIndex = arguments.firstIndex(of: "--render-app-previews") {
        let dir = arguments.count > appIconPreviewsIndex + 1
            ? arguments[appIconPreviewsIndex + 1]
            : "."
        AppIconRenderer.writePreviews(to: dir)
        exit(0)
    }

    if let discsIndex = arguments.firstIndex(of: "--render-discs") {
        let dir = arguments.count > discsIndex + 1
            ? arguments[discsIndex + 1]
            : "."
        renderAllDiscs(to: dir)
        exit(0)
    }

    if let skinIndex = arguments.firstIndex(of: "--skin"),
       arguments.count > skinIndex + 1,
       let skin = SkinID(rawValue: arguments[skinIndex + 1]) {
        Token.activeSkin = skin
    }

    if let renderIndex = arguments.firstIndex(of: "--render") {
        let path = arguments.count > renderIndex + 1
            ? arguments[renderIndex + 1]
            : "spindle.png"
        var artwork: NSImage?
        if let artIndex = arguments.firstIndex(of: "--artwork"),
           arguments.count > artIndex + 1 {
            artwork = NSImage(contentsOfFile: arguments[artIndex + 1])
        }
        renderPrototype(to: path, artwork: artwork)
        exit(0)
    }

    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
