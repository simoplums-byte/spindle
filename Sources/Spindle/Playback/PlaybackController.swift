import AppKit

/// 允许对播放器下发的命令。范围刻意很窄：只有上一曲 / 播放暂停 / 下一曲。
enum PlaybackCommand: String {
    case previous
    case toggle
    case next

    var applescript: String {
        switch self {
        case .previous: return "tell application \"Music\" to previous track"
        case .toggle: return "tell application \"Music\" to playpause"
        case .next: return "tell application \"Music\" to next track"
        }
    }

    static let keyOrder: [PlaybackCommand] = [.previous, .toggle, .next]
}

/// 唯一允许写播放器的地方。只发 AppleScript 命令：
/// 不调音量、不读歌单、不写状态文件、不拉起未运行的 Music。
enum MusicController {
    /// 连点保护：AppleScript 会排队，300ms 内的重复点击直接丢弃。
    private static let minimumInterval: TimeInterval = 0.3
    private nonisolated(unsafe) static var lastFire = Date.distantPast

    static var isMusicRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty
    }

    /// 同步执行，调用方自己负责放到后台队列。返回是否成功。
    static func execute(_ command: PlaybackCommand) -> Bool {
        guard isMusicRunning else { return false }
        var error: NSDictionary?
        NSAppleScript(source: command.applescript)?.executeAndReturnError(&error)
        return error == nil
    }

    /// 给 UI 用：主线程发起，命令跑在后台队列，结束后回主线程回调（用于立刻重采一次样）。
    static func perform(_ command: PlaybackCommand, completion: @escaping () -> Void) {
        guard isMusicRunning else { return }
        let now = Date()
        guard now.timeIntervalSince(lastFire) >= minimumInterval else { return }
        lastFire = now
        DispatchQueue.global(qos: .userInitiated).async {
            _ = execute(command)
            DispatchQueue.main.async { completion() }
        }
    }
}
