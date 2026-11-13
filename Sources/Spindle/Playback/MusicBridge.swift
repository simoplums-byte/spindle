import AppKit

/// Apple Music 的元数据通道。只在 Music 已经在运行时才查询，绝不主动拉起它。
/// 首次调用会触发一次"控制 Music"的自动化授权。
enum MusicBridge {

    struct Snapshot {
        let isPlaying: Bool
        let title: String?
        let artist: String?
    }

    static var isMusicRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty
    }

    /// 读播放状态与曲目文本。阻塞调用，需在后台队列里用。
    /// 暂停时也读曲目：暂停不该让 LCD 掉回 `PAUSE`、也不该让封面碟面消失。
    static func snapshot() -> Snapshot? {
        guard isMusicRunning else { return nil }

        let source = """
        tell application "Music"
            set ps to (player state as text)
            if ps is "stopped" then return "stopped"
            try
                set nm to name of current track
                set ar to artist of current track
                return ps & (ASCII character 1) & nm & (ASCII character 1) & ar
            on error
                return ps
            end try
        end tell
        """

        guard let raw = run(source) else { return nil }
        let parts = raw.components(separatedBy: "\u{01}")
        let isPlaying = parts.first == "playing"
        let title = parts.count > 1 ? parts[1] : nil
        let artist = parts.count > 2 ? parts[2] : nil
        return Snapshot(isPlaying: isPlaying, title: title, artist: artist)
    }

    /// 把当前曲目的封面原始数据导出成图片。没有封面时返回 nil。
    /// 导出内容有变化时才重新读，避免每秒解一次大图。
    static func artwork(destination: URL) -> NSImage? {
        guard isMusicRunning else { return nil }

        let path = destination.path
        let source = """
        tell application "Music"
            if (count of artworks of current track) is 0 then return "none"
            set d to data of artwork 1 of current track
            set fh to open for access (POSIX file "\(path)") with write permission
            set eof fh to 0
            write d to fh
            close access fh
            return "ok"
        end tell
        """

        guard let raw = run(source), raw == "ok" else { return nil }
        guard let data = try? Data(contentsOf: destination), !data.isEmpty else { return nil }
        return NSImage(data: data)
    }

    private static func run(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }
}
