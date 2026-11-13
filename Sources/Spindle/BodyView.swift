import SwiftUI

/// 整机画面。所有尺寸与颜色来自 Token，本文件不出现字面量。
struct RootView: View {
    @ObservedObject var rotation: RotationModel
    @ObservedObject var monitor: PlaybackMonitor

    var body: some View {
        ZStack {
            BodyView(rotation: rotation, nowPlaying: monitor.nowPlaying)
                .frame(width: Token.bodySize, height: Token.bodySize)
        }
        .frame(width: Token.windowSize, height: Token.windowSize)
    }
}

// MARK: - 拖动宿主

/// SwiftUI 的宿主视图默认吃掉鼠标事件，窗口就拖不动。
/// 这里把按下事件直接交给窗口去做拖动。
final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

struct BodyView: View {
    @ObservedObject var rotation: RotationModel
    var nowPlaying: NowPlaying

    var body: some View {
        ZStack(alignment: .topLeading) {
            bodyShell

            lidPlate

            DiscView(angle: rotation.angle, artwork: nowPlaying.artwork)
                .frame(width: Token.discDiameter, height: Token.discDiameter)
                .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 2)
                .offset(centeredOffset(Token.discDiameter))

            Text("SPINDLE")
                .font(.system(size: Token.silkscreenFontSize, weight: .semibold))
                .tracking(Token.silkscreenTracking)
                .foregroundStyle(Token.silkscreenInk.opacity(0.55))
                .position(x: Token.discCenter.x, y: Token.silkscreenBaselineY)

            LCDView(nowPlaying: nowPlaying)
                .offset(x: Token.lcdOrigin.x, y: Token.lcdOrigin.y)

            keys
            sticker
        }
        .frame(width: Token.bodySize, height: Token.bodySize)
    }

    // MARK: 机身

    private var bodyShell: some View {
        RoundedRectangle(cornerRadius: Token.bodyRadius, style: .continuous)
            .fill(LinearGradient(
                colors: [Token.bodyTop, Token.bodyMid, Token.bodyBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
            .overlay(
                RoundedRectangle(cornerRadius: Token.bodyRadius, style: .continuous)
                    .strokeBorder(LinearGradient(
                        stops: [
                            .init(color: Token.bodyRimLight, location: 0.0),
                            .init(color: Token.bodyRimLight.opacity(0.35), location: 0.35),
                            .init(color: Token.bodyRimDark.opacity(0.30), location: 0.65),
                            .init(color: Token.bodyRimDark, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Token.bodyRadius, style: .continuous)
                    .fill(LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.10), location: 0.0),
                            .init(color: .clear, location: 0.22),
                            .init(color: Color.black.opacity(0.04), location: 0.72),
                            .init(color: Color.black.opacity(0.10), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Token.bodyRadius, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.10), .clear],
                        startPoint: .topLeading,
                        endPoint: UnitPoint(x: 0.55, y: 0.45)
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Token.bodyRadius, style: .continuous)
                    .strokeBorder(LinearGradient(
                        colors: [Token.bodyEdgeShadow.opacity(0.30), .clear],
                        startPoint: .top,
                        endPoint: .center
                    ), lineWidth: 2)
            )
            .overlay(
                Group {
                    if Token.hasBrushedTexture {
                        RoundedRectangle(cornerRadius: Token.bodyRadius, style: .continuous)
                            .fill(Token.brushedTexture)
                            .blendMode(.overlay)
                    }
                }
            )
    }

    // MARK: 仓盖

    private var lidPlate: some View {
        Circle()
            .fill(LinearGradient(
                colors: [Token.lidTop, Token.lidBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay(
                Circle().strokeBorder(LinearGradient(
                    colors: [Token.bodyRimLight, Token.bodyRimDark.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1)
            )
            .overlay(
                Circle().strokeBorder(Token.bodyEdgeShadow.opacity(0.18), lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.10), radius: 3, x: 0, y: 1)
            .frame(width: Token.lidPlateDiameter, height: Token.lidPlateDiameter)
            .offset(centeredOffset(Token.lidPlateDiameter))
    }

    // MARK: 按键（完全静态，无按压态）

    private var keys: some View {
        ForEach(Array(Token.keyCentersX.enumerated()), id: \.offset) { _, centerX in
            Circle()
                .fill(LinearGradient(
                    colors: [Token.keyTop, Token.keyBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(Circle().strokeBorder(Token.keyRim.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.10), radius: 1, x: 0, y: 1)
                .frame(width: Token.keyDiameter, height: Token.keyDiameter)
                .offset(x: centerX - Token.keyDiameter / 2,
                        y: Token.keyY - Token.keyDiameter / 2)
        }
    }

    // MARK: 贴纸

    private var sticker: some View {
        ZStack {
            Circle().fill(Token.stickerPaper)
            Circle().strokeBorder(Token.stickerEdge, lineWidth: 1)
            VStack(spacing: 1) {
                Text("SPINDLE")
                    .font(.system(size: Token.stickerFontSize, weight: .bold))
                    .tracking(Token.stickerTracking)
                    .foregroundStyle(Token.stickerInk)
                    .lineLimit(1)
                    .fixedSize()
                Text("AUDIO")
                    .font(.system(size: Token.stickerSubFontSize))
                    .tracking(Token.stickerSubTracking)
                    .foregroundStyle(Token.stickerInk.opacity(0.75))
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .frame(width: Token.stickerDiameter, height: Token.stickerDiameter)
        .rotationEffect(.degrees(Token.stickerRotation))
        .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)
        .offset(x: Token.stickerCenter.x - Token.stickerDiameter / 2,
                y: Token.stickerCenter.y - Token.stickerDiameter / 2)
    }

    private func centeredOffset(_ diameter: CGFloat) -> CGSize {
        CGSize(width: Token.discCenter.x - diameter / 2,
               height: Token.discCenter.y - diameter / 2)
    }
}

// MARK: - 碟片

/// 沿圆周排布的丝印文字。每个字按切线方向旋转。
struct RingText: View {
    let text: String
    let radius: CGFloat
    let step: Double   // 每字间隔角度
    var color: Color? = nil
    var opacity: Double = 0.70

    var body: some View {
        let chars = Array(text)
        let mid = Double(chars.count - 1) / 2
        ZStack {
            ForEach(Array(chars.enumerated()), id: \.offset) { index, char in
                let theta = -90.0 + (Double(index) - mid) * step
                let radians = theta * .pi / 180
                Text(String(char))
                    .font(.system(size: Token.discRingFontSize, weight: .medium))
                    .foregroundStyle((color ?? Token.discSilkscreen).opacity(opacity))
                    .rotationEffect(.degrees(theta + 90))
                    .offset(x: radius * cos(radians),
                            y: radius * sin(radians))
            }
        }
    }
}

// MARK: - LCD

struct LCDView: View {
    var nowPlaying: NowPlaying

    private var isLit: Bool {
        nowPlaying.status == .playing
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Token.lcdRadius, style: .continuous)
                .fill(LinearGradient(
                    colors: [Token.lcdTop, Token.lcdBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))

            RoundedRectangle(cornerRadius: Token.lcdRadius, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.06), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            HStack(spacing: 0) {
                Text(nowPlaying.statusGlyph)
                    .font(Token.lcdStatusFont)
                    .foregroundStyle(isLit ? Token.lcdText : Token.lcdText.opacity(0.50))
                    .frame(width: Token.lcdStatusWidth)

                Rectangle()
                    .fill(Token.lcdText.opacity(0.18))
                    .frame(width: 1, height: 16)

                MarqueeText(text: nowPlaying.lcdLine,
                            width: Token.lcdTextWidth,
                            isScrolling: isLit)
                    .frame(width: Token.lcdTextWidth, height: Token.lcdSize.height - 4)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.08),
                                .init(color: .black, location: 0.92),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .frame(width: Token.lcdSize.width, height: Token.lcdSize.height)
        .clipShape(RoundedRectangle(cornerRadius: Token.lcdRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Token.lcdRadius, style: .continuous)
                .strokeBorder(Token.lcdBezel, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 跑马灯

/// 装得下就居中，装不下就从右往左匀速滚，滚动时首尾各留一段空白。
struct MarqueeText: View {
    let text: String
    let width: CGFloat
    let isScrolling: Bool

    @State private var textWidth: CGFloat = 0

    private var gap: CGFloat { width * Token.marqueeGapRatio }

    var body: some View {
        Group {
            if isScrolling, textWidth > width {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let elapsed = context.date.timeIntervalSinceReferenceDate
                    let travel = Double(textWidth + gap)
                    let period = Token.marqueeHold + travel / Token.marqueeSpeed
                    let phase = elapsed.truncatingRemainder(dividingBy: period)
                    let offset: Double = phase < Token.marqueeHold
                        ? 0
                        : -(phase - Token.marqueeHold) * Token.marqueeSpeed
                    HStack(spacing: gap) {
                        label
                        label
                    }
                    .frame(width: width, alignment: .leading)
                    .offset(x: CGFloat(offset))
                }
            } else {
                label
                    .frame(width: width)
            }
        }
        .frame(width: width, alignment: .center)
        .clipped()
        .onAppear { textWidth = measure(text) }
        .onChange(of: text) { _, newValue in textWidth = measure(newValue) }
    }

    private var label: some View {
        Text(text)
            .font(Token.lcdFont)
            .tracking(Token.lcdTracking)
            .foregroundStyle(Token.lcdText)
            .lineLimit(1)
            .fixedSize()
            .shadow(color: Token.lcdGlow.opacity(0.22), radius: 3)
    }

    private func measure(_ string: String) -> CGFloat {
        let font = NSFont.monospacedSystemFont(ofSize: Token.lcdFontSize, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: Token.lcdTracking
        ]
        return (string as NSString).size(withAttributes: attributes).width
    }
}
