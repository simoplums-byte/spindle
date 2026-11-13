import AppKit

// MARK: - 风格

/// 菜单栏图标怎么表达播放状态。三选一。
enum StatusIconStyle: String, CaseIterable {
    case fill    // 实心 / 空心 / 淡化
    case badge   // 碟 + 右侧角标（▶ / ❚❚）
    case spin    // 转动的残影弧

    var displayName: String {
        switch self {
        case .fill: return "实心切换"
        case .badge: return "角标符号"
        case .spin: return "转动残影"
        }
    }
}

// MARK: - 图标

/// 全部是 template 图：只有 alpha 有意义，深浅色菜单栏由系统反色。
enum StatusIcon {
    nonisolated(unsafe) static var activeStyle: StatusIconStyle = .spin

    static func make(status: PlaybackStatus,
                     style: StatusIconStyle = StatusIcon.activeStyle,
                     pointSize: CGFloat = 18) -> NSImage {
        let width = style == .badge ? pointSize * 1.42 : pointSize
        let image = NSImage(size: NSSize(width: width, height: pointSize), flipped: false) { rect in
            let discCenter = style == .badge
                ? NSPoint(x: rect.minX + pointSize * 0.5, y: rect.midY)
                : NSPoint(x: rect.midX, y: rect.midY)

            let alpha = opacity(for: status)
            let ink = NSColor.black.withAlphaComponent(alpha)
            ink.setStroke()
            ink.setFill()

            switch style {
            case .fill:
                drawFill(center: discCenter, pointSize: pointSize, status: status)
            case .badge:
                drawBadge(center: discCenter, pointSize: pointSize, status: status, canvas: rect)
            case .spin:
                drawSpin(center: discCenter, pointSize: pointSize, status: status)
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Spindle"
        return image
    }

    private static func opacity(for status: PlaybackStatus) -> CGFloat {
        switch status {
        case .playing: return 1.0
        case .paused: return 0.80
        case .idle: return 0.45
        case .unknown: return 0.55
        }
    }

    // MARK: 三种画法

    /// 实心切换：播放时盘面是实心环，暂停变细圈，待机再淡一档
    private static func drawFill(center: NSPoint, pointSize: CGFloat, status: PlaybackStatus) {
        let r = pointSize * 0.40
        let hub = pointSize * 0.105

        if status == .playing {
            let path = NSBezierPath()
            path.appendOval(in: NSRect(x: center.x - r, y: center.y - r, width: r*2, height: r*2))
            path.appendOval(in: NSRect(x: center.x - hub*1.9, y: center.y - hub*1.9,
                                       width: hub*3.8, height: hub*3.8))
            path.windingRule = .evenOdd
            path.fill()
            return
        }

        let outer = NSBezierPath(ovalIn: NSRect(x: center.x - r, y: center.y - r, width: r*2, height: r*2))
        outer.lineWidth = pointSize * 0.095
        outer.stroke()

        let hubPath = NSBezierPath(ovalIn: NSRect(x: center.x - hub, y: center.y - hub,
                                                  width: hub*2, height: hub*2))
        hubPath.lineWidth = pointSize * 0.065
        hubPath.stroke()
    }

    /// 角标符号：碟 + 右侧小符号，需要更宽的画布
    private static func drawBadge(center: NSPoint, pointSize: CGFloat, status: PlaybackStatus, canvas: NSRect) {
        let r = pointSize * 0.40
        let hub = pointSize * 0.105

        let outer = NSBezierPath(ovalIn: NSRect(x: center.x - r, y: center.y - r, width: r*2, height: r*2))
        outer.lineWidth = pointSize * 0.095
        outer.stroke()

        let hubPath = NSBezierPath(ovalIn: NSRect(x: center.x - hub, y: center.y - hub,
                                                  width: hub*2, height: hub*2))
        hubPath.lineWidth = pointSize * 0.065
        hubPath.stroke()

        let glyphX = canvas.maxX - pointSize * 0.30
        switch status {
        case .playing:
            // 小三角
            let tri = NSBezierPath()
            let s = pointSize * 0.30
            tri.move(to: NSPoint(x: glyphX - s * 0.45, y: center.y - s))
            tri.line(to: NSPoint(x: glyphX + s * 0.55, y: center.y))
            tri.line(to: NSPoint(x: glyphX - s * 0.45, y: center.y + s))
            tri.close()
            tri.fill()
        case .paused:
            let s = pointSize * 0.30
            let barW = pointSize * 0.10
            for dx in [-0.22, 0.22] {
                let bar = NSRect(x: glyphX + CGFloat(dx) * s - barW/2,
                                 y: center.y - s,
                                 width: barW, height: s * 2)
                NSBezierPath(rect: bar).fill()
            }
        default:
            break   // 待机不加符号
        }
    }

    /// 转动残影：播放时外圈留一个缺口并拖一段渐隐尾迹，暂停时是闭合的细环
    private static func drawSpin(center: NSPoint, pointSize: CGFloat, status: PlaybackStatus) {
        let r = pointSize * 0.40
        let hub = pointSize * 0.105

        let hubPath = NSBezierPath(ovalIn: NSRect(x: center.x - hub, y: center.y - hub,
                                                  width: hub*2, height: hub*2))
        hubPath.lineWidth = pointSize * 0.065
        hubPath.stroke()

        let ringWidth = pointSize * 0.095

        if status == .playing {
            // 主环：330° 闭合，右上留缺口
            let main = NSBezierPath()
            main.appendArc(withCenter: center, radius: r, startAngle: 38, endAngle: 330, clockwise: false)
            main.lineWidth = ringWidth
            main.stroke()

            // 缺口里拖一段更淡更细的尾迹，表示"刚转过去"
            let trail = NSBezierPath()
            trail.appendArc(withCenter: center, radius: r, startAngle: 338, endAngle: 356, clockwise: false)
            trail.lineWidth = ringWidth * 0.45
            NSColor.black.withAlphaComponent(0.45).setStroke()
            trail.stroke()

            // 盘面里一道静态高光弧，跟其他样式同一个语言
            let shine = NSBezierPath()
            shine.appendArc(withCenter: center, radius: r - pointSize * 0.14, startAngle: 120, endAngle: 200)
            shine.lineWidth = pointSize * 0.05
            NSColor.black.withAlphaComponent(0.75).setStroke()
            shine.stroke()
            return
        }

        let outer = NSBezierPath(ovalIn: NSRect(x: center.x - r, y: center.y - r, width: r*2, height: r*2))
        outer.lineWidth = ringWidth
        outer.stroke()

        if status != .idle {
            let arc = NSBezierPath()
            arc.appendArc(withCenter: center, radius: r - pointSize * 0.14, startAngle: 118, endAngle: 198)
            arc.lineWidth = pointSize * 0.05
            arc.stroke()
        }
    }
}
