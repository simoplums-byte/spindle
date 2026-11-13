import AppKit

enum PlaybackStatus: Equatable {
    case playing
    case paused      // 播放器开着，但没在出声
    case idle        // 播放器没开
    case unknown     // 刚启动，还没采到两次一致的结果
}

enum PlaybackSource: String, Equatable {
    case none
    case netease
    case spotify
    case music
    case browser
    case other

    var displayName: String {
        switch self {
        case .none: return ""
        case .netease: return "NETEASE"
        case .spotify: return "SPOTIFY"
        case .music: return "MUSIC"
        case .browser: return "BROWSER"
        case .other: return "PLAYER"
        }
    }
}

/// 一帧"唱片机该显示什么"。检测层每轮采样产出一个。
struct NowPlaying: Equatable {
    var status: PlaybackStatus = .unknown
    var source: PlaybackSource = .none
    var title: String?
    var artist: String?
    var artwork: NSImage?

    static func == (lhs: NowPlaying, rhs: NowPlaying) -> Bool {
        lhs.status == rhs.status
            && lhs.source == rhs.source
            && lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.artwork === rhs.artwork
    }

    var hasTitle: Bool {
        guard let t = title else { return false }
        return !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 跑马灯文案。有曲名就是"曲名 · 艺人"，取不到就退回来源 + 状态。
    var lcdLine: String {
        switch status {
        case .idle, .unknown:
            return Token.lcdIdle
        case .paused:
            if hasTitle, let t = title {
                return artist.map { "\(t) · \($0)" } ?? t
            }
            return Token.lcdPaused
        case .playing:
            if hasTitle, let t = title {
                return artist.map { "\(t) · \($0)" } ?? t
            }
            switch source {
            case .netease, .spotify, .music, .browser, .other:
                return "\(source.displayName) · PLAYING"
            case .none:
                return Token.lcdFallbackPlaying
            }
        }
    }

    var statusGlyph: String {
        switch status {
        case .playing: return "▶"
        case .paused: return "II"
        case .idle, .unknown: return "■"
        }
    }
}
