import AppKit

/// 把「三种风格 × 三种状态」排成一张对照图，供挑选。
enum StatusIconBoard {
    static func render(to path: String) {
        let states: [(PlaybackStatus, String)] = [
            (.playing, "播放中"),
            (.paused, "已暂停"),
            (.idle, "待机")
        ]
        let styles = StatusIconStyle.allCases

        let cellW: CGFloat = 132
        let cellH: CGFloat = 110
        let headerH: CGFloat = 44
        let gap: CGFloat = 12
        let width = CGFloat(styles.count) * cellW + CGFloat(styles.count + 1) * gap
        let height = headerH + CGFloat(states.count) * cellH + CGFloat(states.count) * gap + gap * 2

        let scale: CGFloat = 2
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.cgContext.scaleBy(x: scale, y: scale)

        NSColor(calibratedRed: 0.93, green: 0.93, blue: 0.94, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()

        // 列标题
        let titlePara = NSMutableParagraphStyle()
        titlePara.alignment = .center
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor(calibratedWhite: 0.25, alpha: 1),
            .paragraphStyle: titlePara
        ]
        for (col, style) in styles.enumerated() {
            let x = gap + CGFloat(col) * (cellW + gap)
            (style.displayName as NSString).draw(
                in: NSRect(x: x, y: height - gap - 18, width: cellW, height: 18),
                withAttributes: titleAttrs
            )
        }

        for (row, pair) in states.enumerated() {
            let y = height - headerH - gap - CGFloat(row + 1) * (cellH + gap) + gap
            for (col, style) in styles.enumerated() {
                let x = gap + CGFloat(col) * (cellW + gap)

                NSColor.white.setFill()
                NSBezierPath(roundedRect: NSRect(x: x, y: y, width: cellW, height: cellH),
                             xRadius: 10, yRadius: 10).fill()

                // 左列标状态，右侧画图标
                let rowPara = NSMutableParagraphStyle()
                rowPara.alignment = .left
                let rowAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor(calibratedWhite: 0.45, alpha: 1),
                    .paragraphStyle: rowPara
                ]
                if col == 0 {
                    (pair.1 as NSString).draw(
                        in: NSRect(x: x + 12, y: y + cellH - 26, width: cellW - 24, height: 16),
                        withAttributes: rowAttrs
                    )
                }

                let icon = StatusIcon.make(status: pair.0, style: style)
                let iconSize = icon.size
                let origin = NSPoint(x: x + cellW / 2 - iconSize.width / 2,
                                     y: y + cellH / 2 - iconSize.height / 2 - 6)
                icon.draw(in: NSRect(origin: origin, size: iconSize))
            }
        }

        NSGraphicsContext.restoreGraphicsState()

        do {
            let data = rep.representation(using: .png, properties: [:])!
            try data.write(to: URL(fileURLWithPath: path))
            print("rendered \(path)")
        } catch {
            FileHandle.standardError.write("write failed: \(error)\n".data(using: .utf8)!)
        }
    }
}
