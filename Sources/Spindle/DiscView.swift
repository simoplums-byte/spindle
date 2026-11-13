import SwiftUI

// MARK: - 碟面样式

/// 碟面观感。与皮肤正交：任何皮肤都能配任何碟面。
enum DiscStyle: String, CaseIterable, Identifiable {
    case albumArt    // 当前曲目的专辑封面（拿不到封面时不出现）
    case silver      // 银色压模 + 外圈彩虹带（初版）
    case hologram    // 全盘全息彩虹
    case label       // 银色盘 + 内圈印刷标签
    case crystal     // 半透明盘，透出内部机构
    case gold        // 归档金碟
    case jibuli      // 私人印刷盘：吉卜李

    var id: String { rawValue }

    /// 自有碟面：盘面由代码画出来，不依赖封面
    var isMaterial: Bool { self != .albumArt }

    static var materials: [DiscStyle] { allCases.filter(\.isMaterial) }

    var displayName: String {
        switch self {
        case .albumArt: return "专辑封面"
        case .silver: return "银色压模"
        case .hologram: return "全息彩虹"
        case .label: return "印刷标签"
        case .crystal: return "透明水晶"
        case .gold: return "金碟"
        case .jibuli: return "吉卜李"
        }
    }

    var caption: String {
        switch self {
        case .albumArt: return "正在放的这首，封面直接印在盘上"
        case .silver: return "最像随手从盒子里抽出来的那张"
        case .hologram: return "转动时整盘颜色会跟着走"
        case .label: return "像自己刻的碟，正反面不一样"
        case .crystal: return "能看见马达和辐条，最 Discman"
        case .gold: return "暖金、克制，晚上看不刺眼"
        case .jibuli: return "自己刻的那张，整盘只有一张画"
        }
    }
}

/// 碟面专用色值。和皮肤色分开，避免互相牵制。
enum DiscToken {
    /// 跟随封面：为 true 时，当前曲目有封面就优先用 `albumArt`。
    nonisolated(unsafe) static var autoArtwork = true

    /// 用户手选的自有碟面；没有封面时回落到它。
    nonisolated(unsafe) static var active: DiscStyle = .silver

    /// 当前实际生效的碟面。封面只在 `albumArt` 下参与绘制。
    static func effective(for artwork: NSImage?) -> DiscStyle {
        if autoArtwork && artwork != nil { return .albumArt }
        return active == .albumArt ? .silver : active
    }

    /// 用户在菜单里做出的选择。选自有碟面即关闭"跟随封面"。
    static func select(_ style: DiscStyle) {
        if style == .albumArt {
            autoArtwork = true
        } else {
            autoArtwork = false
            active = style
        }
    }

    // 全息
    static let holoTop = Color(hex: 0xF1F4F8)
    static let holoBottom = Color(hex: 0xCFD8E3)
    static let holoInk = Color(hex: 0xF7FAFF)
    static let holoViolet = Color(hex: 0xC9A6EE)

    // 印刷标签
    static let labelPaperTop = Color(hex: 0xFBF8F0)
    static let labelPaperBottom = Color(hex: 0xEDE5D3)
    static let labelEdge = Color(hex: 0xC8BEAA)
    static let labelInk = Color(hex: 0x33302A)

    // 透明水晶
    static let crystalTop = Color(hex: 0xFFFFFF)
    static let crystalBottom = Color(hex: 0xD8E4EF)
    static let crystalInk = Color(hex: 0x3D464F)

    // 金碟
    static let goldTop = Color(hex: 0xF6E4B8)
    static let goldMid = Color(hex: 0xD3AE63)
    static let goldBottom = Color(hex: 0x8F6C36)
    static let goldSheen = Color(hex: 0xFFF6DC)
    static let goldInk = Color(hex: 0x4E3B1B)
}

// MARK: - 碟面

struct DiscView: View {
    let angle: Double
    var artwork: NSImage? = nil

    private var style: DiscStyle { DiscToken.effective(for: artwork) }

    /// 只有「专辑封面」碟面才把封面铺上盘面；自有碟面画自己的盘面。
    private var showsArtwork: Bool { style == .albumArt }

    var body: some View {
        ZStack {
            if showsArtwork, let artwork {
                artworkSurface(artwork)
            } else {
                baseSurface
            }
            finish
        }
        .clipShape(Circle())
        .rotationEffect(.degrees(angle))
        .drawingGroup()
    }

    // MARK: 底层

    @ViewBuilder
    private var baseSurface: some View {
        switch style {
        // 拿不到封面的「专辑封面」碟面回落到银色压模，与默认观感一致
        case .albumArt, .silver: silverSurface
        case .hologram: hologramSurface
        case .label: labelSurface
        case .crystal: crystalSurface
        case .gold: goldSurface
        case .jibuli: jibuliSurface
        }
    }

    private func artworkSurface(_ image: NSImage) -> some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: Token.discDiameter, height: Token.discDiameter)
                .clipShape(Circle())
                .saturation(Token.discArtworkSaturation)
                .overlay(Circle().fill(Color.white.opacity(Token.discArtworkVeil)))

            Circle().fill(AngularGradient(
                gradient: Gradient(colors: iridescent(alpha: Token.iridescentWashAlpha)),
                center: .center,
                angle: .degrees(18)
            ))
        }
    }

    private var silverSurface: some View {
        ZStack {
            Circle().fill(LinearGradient(
                colors: [Token.discBase, Token.discInner],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))

            Circle().fill(AngularGradient(
                gradient: Gradient(colors: iridescent(alpha: Token.iridescentWashAlpha)),
                center: .center,
                angle: .degrees(18)
            ))

            // 彩虹集中在碟面外圈的环带，而不是把整张碟染色
            Circle().fill(AngularGradient(
                gradient: Gradient(colors: iridescent(alpha: Token.iridescentBandAlpha)),
                center: .center,
                angle: .degrees(18)
            ))
            .mask(
                Circle()
                    .stroke(lineWidth: Token.iridescentBandWidth)
                    .frame(width: Token.iridescentBandDiameter, height: Token.iridescentBandDiameter)
            )
        }
    }

    /// 全息：整盘干涉色，两个角度的彩虹叠一层，转动时颜色会大片流动
    private var hologramSurface: some View {
        ZStack {
            Circle().fill(LinearGradient(
                colors: [DiscToken.holoTop, DiscToken.holoBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))

            Circle().fill(AngularGradient(
                gradient: Gradient(colors: [
                    Token.iridescentPink.opacity(0.66),
                    DiscToken.holoViolet.opacity(0.60),
                    Token.iridescentMint.opacity(0.62),
                    Token.iridescentSky.opacity(0.68),
                    Token.iridescentGold.opacity(0.55),
                    Token.iridescentPink.opacity(0.66)
                ]),
                center: .center,
                angle: .degrees(14)
            ))

            Circle().fill(AngularGradient(
                gradient: Gradient(colors: iridescent(alpha: 0.34)),
                center: .center,
                angle: .degrees(68)
            ))
            .blendMode(.overlay)

            Circle().fill(RadialGradient(
                colors: [Color.white.opacity(0.34), .clear],
                center: UnitPoint(x: 0.32, y: 0.26),
                startRadius: 0,
                endRadius: 105
            ))
        }
        .saturation(1.35)
    }

    /// 印刷标签：外圈银色压模，内圈一张米白纸质标签
    private var labelSurface: some View {
        ZStack {
            Circle().fill(LinearGradient(
                colors: [Token.discBase, Token.discInner],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))

            // 金属盘面只剩很淡的一层冷调
            Circle().fill(AngularGradient(
                gradient: Gradient(colors: iridescent(alpha: 0.10)),
                center: .center,
                angle: .degrees(18)
            ))

            Circle()
                .fill(LinearGradient(
                    colors: [DiscToken.labelPaperTop, DiscToken.labelPaperBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 126, height: 126)
                .overlay(Circle().strokeBorder(DiscToken.labelEdge, lineWidth: 1))
                .overlay(alignment: .top) {
                    HStack(spacing: 2.5) {
                        ForEach(Array(iridescentColors.enumerated()), id: \.offset) { index, color in
                            Rectangle()
                                .fill(color.opacity(index == 0 ? 0.55 : 0.42))
                                .frame(width: 3, height: 10)
                        }
                    }
                    .offset(y: 9)
                }
                .overlay(alignment: .top) {
                    VStack(spacing: 2) {
                        Text("SPINDLE")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1.6)
                        Text("AUDIO · 74 MIN")
                            .font(.system(size: 4.6, weight: .medium))
                            .tracking(0.8)
                    }
                    .foregroundStyle(DiscToken.labelInk)
                    .offset(y: 26)
                }
        }
    }

    /// 透明水晶：半透明盘，透出马达、辐条和压盘环
    private var crystalSurface: some View {
        ZStack {
            Circle().fill(RadialGradient(
                colors: [
                    DiscToken.crystalTop.opacity(0.97),
                    DiscToken.crystalBottom.opacity(0.90)
                ],
                center: UnitPoint(x: 0.36, y: 0.28),
                startRadius: 0,
                endRadius: 110
            ))

            // 机身色透出一点，才有"透明"的感觉
            Circle().fill(Token.bodyMid.opacity(0.10))

            // 内部辐条
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(Color.black.opacity(0.055))
                    .frame(width: 74, height: 1.6)
                    .offset(x: 40)
                    .rotationEffect(.degrees(Double(index) * 60 + 12))
            }

            // 压盘环与马达外壳
            Circle().strokeBorder(Color.black.opacity(0.09), lineWidth: 1)
                .frame(width: 92, height: 92)
            Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                .frame(width: 94, height: 94)
            Circle().strokeBorder(Color.black.opacity(0.07), lineWidth: 7)
                .frame(width: 66, height: 66)
            Circle().fill(RadialGradient(
                colors: [Color.black.opacity(0.10), .clear],
                center: .center,
                startRadius: 8,
                endRadius: 40
            ))
            .frame(width: 80, height: 80)

            Circle().fill(RadialGradient(
                colors: [Color.white.opacity(0.5), .clear],
                center: UnitPoint(x: 0.30, y: 0.24),
                startRadius: 0,
                endRadius: 80
            ))
        }
    }

    /// 金碟：暖金金属，彩虹只留一点点
    private var goldSurface: some View {
        ZStack {
            Circle().fill(LinearGradient(
                colors: [DiscToken.goldTop, DiscToken.goldMid, DiscToken.goldBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))

            Circle().fill(LinearGradient(
                colors: [
                    DiscToken.goldSheen.opacity(0.50),
                    .clear,
                    .clear,
                    Color.black.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))

            Circle().fill(AngularGradient(
                gradient: Gradient(colors: iridescent(alpha: 0.12)),
                center: .center,
                angle: .degrees(18)
            ))
        }
    }

    /// 吉卜李：一张预先压好的印刷标签，整盘就是一整块图案
    @ViewBuilder
    private var jibuliSurface: some View {
        if let art = DiscArtwork.jibuli {
            Image(nsImage: art)
                .resizable()
                .interpolation(.high)
                .frame(width: Token.discDiameter, height: Token.discDiameter)
                .clipShape(Circle())
        } else {
            silverSurface
        }
    }

    // MARK: 公共表层

    @ViewBuilder
    private var finish: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [.clear, Color.white.opacity(glareAlpha), .clear],
                startPoint: .top,
                endPoint: .bottom
            ))
            .frame(width: Token.discDiameter * 1.6, height: Token.discGlareWidth)
            .rotationEffect(.degrees(Token.discGlareAngle))

        if style != .jibuli && style != .label {
            Circle().fill(RadialGradient(
                colors: [Color.white.opacity(0.28), .clear],
                center: UnitPoint(x: 0.30, y: 0.22),
                startRadius: 0,
                endRadius: 90
            ))
        }

        if style != .jibuli {
            ForEach(Token.discRingDiameters, id: \.self) { diameter in
                Circle()
                    .strokeBorder(Color.white.opacity(ringAlpha), lineWidth: 1)
                    .frame(width: diameter, height: diameter)
            }
        }

        if !showsArtwork && style != .label && style != .jibuli {
            RingText(text: "SPINDLE",
                     radius: Token.discSilkscreenRadius,
                     step: 7.0,
                     color: silkColor,
                     opacity: silkOpacity)
        }

        if style != .jibuli {
            // 图案类碟面整盘只放一张画，实心轴环会在脸上落一块灰斑、中心孔会正好开在五官上
            Circle()
                .fill(RadialGradient(
                    colors: [hubColor, hubColor.opacity(0.65)],
                    center: .center,
                    startRadius: 0,
                    endRadius: Token.hubDiameter / 2
                ))
                .frame(width: Token.hubDiameter, height: Token.hubDiameter)

            Circle()
                .fill(Token.discHole)
                .frame(width: Token.holeDiameter, height: Token.holeDiameter)

            Circle()
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                .frame(width: Token.holeDiameter + 1, height: Token.holeDiameter + 1)
        }

        Circle().fill(RadialGradient(
            colors: [.clear, Color.black.opacity(0.16)],
            center: .center,
            startRadius: 72,
            endRadius: 100
        ))

        Circle().strokeBorder(Token.discEdge.opacity(0.45), lineWidth: 1)
    }

    // MARK: 样式差异

    private var iridescentColors: [Color] {
        [Token.iridescentPink, Token.iridescentGold, Token.iridescentMint,
         Token.iridescentSky, Token.iridescentPink]
    }

    private func iridescent(alpha: Double) -> [Color] {
        iridescentColors.map { $0.opacity(alpha) }
    }

    private var glareAlpha: Double {
        switch style {
        case .albumArt: return Token.discGlareAlpha
        case .silver: return Token.discGlareAlpha
        case .hologram: return 0.26
        case .label: return 0.12
        case .crystal: return 0.30
        case .gold: return 0.22
        case .jibuli: return 0.14
        }
    }

    private var ringAlpha: Double {
        switch style {
        case .albumArt: return 0.16
        case .silver: return 0.16
        case .hologram: return 0.10
        case .label: return 0.12
        case .crystal: return 0.10
        case .gold: return 0.12
        case .jibuli: return 0.10
        }
    }

    private var silkColor: Color {
        switch style {
        case .albumArt: return Token.discSilkscreen
        case .silver: return Token.discSilkscreen
        case .hologram: return DiscToken.holoInk
        case .label: return DiscToken.labelInk
        case .crystal: return DiscToken.crystalInk
        case .gold: return DiscToken.goldInk
        case .jibuli: return DiscToken.goldInk
        }
    }

    private var silkOpacity: Double {
        style == .hologram ? 0.92 : 0.70
    }

    private var hubColor: Color {
        switch style {
        case .gold: return Color(hex: 0xB08B4C)
        case .crystal: return Color(hex: 0xCBD5DE)
        case .jibuli: return Color.white.opacity(0.42)
        default: return Token.discHub
        }
    }
}
