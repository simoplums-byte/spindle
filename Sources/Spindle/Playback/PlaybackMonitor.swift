import AppKit

/// 每秒采一次，连续两次同向才切换状态（去抖动）。
/// 主判据是 CoreAudio 的进程音频活动，Apple Music 额外补曲名与封面。
@MainActor
final class PlaybackMonitor: ObservableObject {

    @Published private(set) var nowPlaying = NowPlaying()

    /// 状态变化回调，给旋转模型用。
    var onStatusChange: ((PlaybackStatus) -> Void)?

    private var timer: Timer?
    private var pending: PlaybackStatus?
    private var pendingCount = 0
    private var lastMusicQuery = Date.distantPast
    private var lastArtworkKey: String?

    private let sampleInterval: TimeInterval = 1.0
    private let metadataInterval: TimeInterval = 2.0
    private let queue = DispatchQueue(label: "com.seanli.spindle.playback")
    private let artworkURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("spindle-artwork.bin")

    private static let whitelist: [String: PlaybackSource] = [
        "com.netease.163music": .netease,
        "com.spotify.client": .spotify,
        "com.apple.Music": .music,
        "com.apple.iTunes": .music,
        "com.electron.yesplaymusic": .other
    ]

    // MARK: 生命周期

    func start() {
        guard timer == nil else { return }
        sample()
        let t = Timer(timeInterval: sampleInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sample() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: 采样

    private func sample() {
        let processes = CoreAudioReader.processes()
        let activeSource = processes.first { process in
            process.isRunning && PlaybackMonitor.source(forPath: process.execPath) != nil
        }

        let raw: PlaybackStatus
        let source: PlaybackSource

        if let process = activeSource, let s = PlaybackMonitor.source(forPath: process.execPath) {
            raw = .playing
            source = s
        } else if let running = PlaybackMonitor.runningPlayer() {
            raw = .paused
            source = running
        } else {
            raw = .idle
            source = .none
        }

        apply(raw: raw, source: source)
    }

    /// 两次同向才认，避免切歌时的一秒空档把碟片刹停。
    private func apply(raw: PlaybackStatus, source: PlaybackSource) {
        if nowPlaying.status == raw {
            pending = nil
            pendingCount = 0
            if nowPlaying.source != source {
                nowPlaying.source = source
                if source != .music { clearMetadata() }
            }
            refreshMetadataIfNeeded()
            return
        }

        if pending == raw {
            pendingCount += 1
        } else {
            pending = raw
            pendingCount = 1
        }

        guard pendingCount >= 2 else { return }

        pending = nil
        pendingCount = 0
        nowPlaying.status = raw
        nowPlaying.source = source
        // 来源不再是 Apple Music（或已待机）时，曲名与封面都不可信，立刻清掉
        if raw == .idle || source != .music {
            clearMetadata()
        }
        onStatusChange?(raw)
        refreshMetadataIfNeeded()
    }

    private func clearMetadata() {
        nowPlaying.title = nil
        nowPlaying.artist = nil
        nowPlaying.artwork = nil
        lastArtworkKey = nil
    }

    // MARK: 元数据（仅 Apple Music）

    private func refreshMetadataIfNeeded() {
        guard nowPlaying.source == .music else { return }
        let now = Date()
        guard now.timeIntervalSince(lastMusicQuery) >= metadataInterval else { return }
        lastMusicQuery = now

        // 旧 key 在派发前取好，后台只做比较，不回写主线程状态
        let previousKey = lastArtworkKey
        queue.async { [weak self] in
            guard let self else { return }
            guard let snapshot = MusicBridge.snapshot() else { return }
            let key = "\(snapshot.title ?? "")|\(snapshot.artist ?? "")"
            // 曲目变了才重取封面；取不到（这首没封面/导出失败）时把旧封面一并清掉，
            // 否则会拿上一首的封面继续转。
            let keyChanged = key != previousKey
            let artwork = keyChanged ? MusicBridge.artwork(destination: self.artworkURL) : nil
            Task { @MainActor in
                self.nowPlaying.title = snapshot.title
                self.nowPlaying.artist = snapshot.artist
                guard key != self.lastArtworkKey else { return }
                self.lastArtworkKey = key
                self.nowPlaying.artwork = artwork
            }
        }
    }

    // MARK: 工具

    private static func source(forPath path: String) -> PlaybackSource? {
        guard !path.isEmpty else { return nil }
        // 系统服务与模拟器的音频不算"有人在放音乐"
        if path.contains("simruntime") || path.contains("systemsoundserver") { return nil }
        if path.contains("/NeteaseMusic.app/") { return .netease }
        if path.contains("/Spotify.app/") { return .spotify }
        if path.contains("/Music.app/") { return .music }
        if path.contains("/Google Chrome.app/")
            || path.contains("/Microsoft Edge.app/")
            || path.contains("/Firefox.app/")
            || path.contains("/Safari.app/")
            || path.contains("com.apple.WebKit") {
            return .browser
        }
        if path.contains("/YesPlayMusic.app/") { return .other }
        return nil
    }

    /// 只认音乐播放器，浏览器不算——Chrome 常年开着，否则永远进不了待机。
    private static func runningPlayer() -> PlaybackSource? {
        let apps = NSWorkspace.shared.runningApplications
        for (bundleID, source) in whitelist
        where apps.contains(where: { $0.bundleIdentifier == bundleID }) {
            return source
        }
        return nil
    }
}
