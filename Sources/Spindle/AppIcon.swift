import AppKit

// MARK: - 配色方案

/// 应用图标的四套配色候选。四套共用同一张碟片线稿，只换底与线色。
enum AppIconScheme: String, CaseIterable {
    case champagne   // 香槟银：与机身同族
    case graphite    // 石墨黑：深底亮线（默认，v1.9 定稿）
    case lcd         // LCD 深蓝：冷底冰蓝线
    case steel       // 拉丝钢：冷银底深墨线

    var displayName: String {
        switch self {
        case .champagne: return "香槟银"
        case .graphite: return "石墨黑"
        case .lcd: return "LCD 深蓝"
        case .steel: return "拉丝钢"
        }
    }

    var note: String {
        switch self {
        case .champagne: return "跟机身同一套金属色，最像这台机器本身"
        case .graphite: return "深底亮线，浅色 Dock 上轮廓最清楚"
        case .lcd: return "取 LCD 的蓝，冷、安静，夜里不刺眼"
        case .steel: return "冷银底 + 深墨线，工业感最强"
        }
    }

    /// 底板竖直渐变（上 → 下）
    var background: [NSColor] {
        switch self {
        case .champagne:
            return [NSColor(hex: 0xF8F2E8), NSColor(hex: 0xD3C8B4), NSColor(hex: 0xAFA28C)]
        case .graphite:
            return [NSColor(hex: 0x45454A), NSColor(hex: 0x35353A), NSColor(hex: 0x1E1E22)]
        case .lcd:
            return [NSColor(hex: 0x0B2A38), NSColor(hex: 0x061A24)]
        case .steel:
            return [NSColor(hex: 0xDCE0E3), NSColor(hex: 0xB3B8BC), NSColor(hex: 0x84898E)]
        }
    }

    /// 碟片线稿的颜色
    var ink: NSColor {
        switch self {
        case .champagne: return NSColor(hex: 0x5A5145)
        case .graphite: return NSColor(hex: 0xF2EADA)
        case .lcd: return NSColor(hex: 0x7FD8FF)
        case .steel: return NSColor(hex: 0x3E444A)
        }
    }

    /// 底板描边
    var rim: NSColor {
        switch self {
        case .champagne: return NSColor(hex: 0x8E8271).withAlphaComponent(0.55)
        case .graphite: return NSColor(hex: 0x7C7C84).withAlphaComponent(0.55)
        case .lcd: return NSColor(hex: 0x4FC8F5).withAlphaComponent(0.35)
        case .steel: return NSColor(hex: 0x5C6166).withAlphaComponent(0.55)
        }
    }
}

private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

// MARK: - 渲染

/// 应用图标：macOS 的圆角方板 + 菜单栏那套碟片线稿（闭合细环版，不带转动残影）。
enum AppIconRenderer {

    /// 当前配色。四套候选见 `AppIconScheme`，定稿为石墨黑（v1.9）。
    nonisolated(unsafe) static var scheme: AppIconScheme = .graphite

    private static let iconsetSizes: [(name: String, px: CGFloat)] = [
        ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
    ]

    // MARK: 画

    static func draw(in rect: NSRect, scheme: AppIconScheme) {
        let side = min(rect.width, rect.height)
        let inset = side * 0.082
        let plate = rect.insetBy(dx: inset, dy: inset)
        let radius = plate.width * 0.225
        let platePath = NSBezierPath(roundedRect: plate, xRadius: radius, yRadius: radius)

        // 投影：让圆角板从背景里浮起来，和窗口那层投影同源
        NSGraphicsContext.current?.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        shadow.shadowBlurRadius = side * 0.045
        shadow.shadowOffset = NSSize(width: 0, height: -side * 0.018)
        shadow.set()
        scheme.background.first?.setFill()
        platePath.fill()
        NSGraphicsContext.current?.restoreGraphicsState()

        // 底板：竖直金属渐变 + 上半区一层柔和高光
        NSGraphicsContext.current?.saveGraphicsState()
        platePath.addClip()
        NSGradient(colors: scheme.background)?.draw(in: plate, angle: -90)
        NSGradient(colors: [NSColor.white.withAlphaComponent(0.22), .clear])?
            .draw(in: NSRect(x: plate.minX, y: plate.midY,
                             width: plate.width, height: plate.height / 2),
                  angle: -90)
        NSGraphicsContext.current?.restoreGraphicsState()

        platePath.lineWidth = max(1, side * 0.0045)
        scheme.rim.setStroke()
        platePath.stroke()

        drawDiscLineArt(center: NSPoint(x: plate.midX, y: plate.midY),
                        plateWidth: plate.width,
                        ink: scheme.ink)
    }

    /// 与 `StatusIcon` 的 `spin` 暂停态同一套语言：闭合外环 + 中心毂 + 一道高光弧
    private static func drawDiscLineArt(center: NSPoint, plateWidth: CGFloat, ink: NSColor) {
        ink.setStroke()

        let r = plateWidth * 0.305
        let outer = NSBezierPath(ovalIn: NSRect(x: center.x - r, y: center.y - r,
                                                width: r * 2, height: r * 2))
        outer.lineWidth = plateWidth * 0.040
        outer.stroke()

        let hubR = plateWidth * 0.082
        let hub = NSBezierPath(ovalIn: NSRect(x: center.x - hubR, y: center.y - hubR,
                                              width: hubR * 2, height: hubR * 2))
        hub.lineWidth = plateWidth * 0.026
        hub.stroke()

        let shine = NSBezierPath()
        shine.appendArc(withCenter: center,
                        radius: r - plateWidth * 0.10,
                        startAngle: 118, endAngle: 198)
        shine.lineWidth = plateWidth * 0.020
        shine.stroke()
    }

    // MARK: 输出

    private static func bitmap(size: CGFloat, scheme: AppIconScheme) -> NSBitmapImageRep {
        let px = Int(size)
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: px, pixelsHigh: px,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.cgContext.clear(NSRect(x: 0, y: 0, width: size, height: size))
        draw(in: NSRect(x: 0, y: 0, width: size, height: size), scheme: scheme)
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    static func pngData(size: CGFloat, scheme: AppIconScheme) -> Data? {
        bitmap(size: size, scheme: scheme).representation(using: .png, properties: [:])
    }

    /// 写出一套 `AppIcon.iconset`（目录需已存在）。
    static func writeIconset(to directory: String) {
        for entry in iconsetSizes {
            guard let data = pngData(size: entry.px, scheme: scheme) else { continue }
            let path = (directory as NSString).appendingPathComponent(entry.name)
            try? data.write(to: URL(fileURLWithPath: path))
        }
        print("rendered iconset \(directory) scheme=\(scheme.rawValue)")
    }

    /// 四套配色各出一张大图 + 一张对照表，供挑选。
    static func writePreviews(to directory: String) {
        for candidate in AppIconScheme.allCases {
            guard let data = pngData(size: 512, scheme: candidate) else { continue }
            let path = (directory as NSString).appendingPathComponent("appicon-\(candidate.rawValue)@2x.png")
            try? data.write(to: URL(fileURLWithPath: path))
        }
        let sheet = (directory as NSString).appendingPathComponent("appicon-schemes@2x.png")
        writeContactSheet(to: sheet)
        print("rendered previews \(directory)")
    }

    private static func writeContactSheet(to path: String) {
        let cellW: CGFloat = 520
        let cellH: CGFloat = 600
        let gap: CGFloat = 40
        let margin: CGFloat = 40
        let cols = 2
        let rows = (AppIconScheme.allCases.count + cols - 1) / cols
        let width = margin * 2 + CGFloat(cols) * cellW + CGFloat(cols - 1) * gap
        let height = margin * 2 + CGFloat(rows) * cellH + CGFloat(rows - 1) * gap

        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(width), pixelsHigh: Int(height),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        NSColor(hex: 0xEDECEA).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()

        let titleStyle = NSMutableParagraphStyle()
        titleStyle.alignment = .center
        let noteStyle = NSMutableParagraphStyle()
        noteStyle.alignment = .center

        for (index, candidate) in AppIconScheme.allCases.enumerated() {
            let col = index % cols
            let row = index / cols
            let x = margin + CGFloat(col) * (cellW + gap)
            // 从顶部往下排
            let y = height - margin - CGFloat(row + 1) * cellH - CGFloat(row) * gap

            NSColor.white.setFill()
            NSBezierPath(roundedRect: NSRect(x: x, y: y, width: cellW, height: cellH),
                         xRadius: 16, yRadius: 16).fill()

            let iconSize: CGFloat = 420
            let iconRect = NSRect(x: x + (cellW - iconSize) / 2,
                                  y: y + cellH - iconSize - 34,
                                  width: iconSize, height: iconSize)
            draw(in: iconRect, scheme: candidate)

            // 小尺寸可读性对照
            let smallSize: CGFloat = 44
            draw(in: NSRect(x: x + 34, y: y + 34, width: smallSize, height: smallSize),
                 scheme: candidate)

            (candidate.displayName as NSString).draw(
                in: NSRect(x: x + 90, y: y + 66, width: cellW - 120, height: 22),
                withAttributes: [
                    .font: NSFont.systemFont(ofSize: 17, weight: .semibold),
                    .foregroundColor: NSColor(hex: 0x2B2A27),
                    .paragraphStyle: titleStyle
                ])

            (candidate.note as NSString).draw(
                in: NSRect(x: x + 90, y: y + 40, width: cellW - 120, height: 20),
                withAttributes: [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor(hex: 0x77726A),
                    .paragraphStyle: noteStyle
                ])
        }

        NSGraphicsContext.restoreGraphicsState()

        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
}
