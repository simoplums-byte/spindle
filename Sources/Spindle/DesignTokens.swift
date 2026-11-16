import SwiftUI

// 视觉 token 的唯一实现处。数值定义见 docs/design/visual-spec.md。
// View 内不得出现颜色 hex、字号或时长字面量。
// 颜色全部来自当前皮肤，切换皮肤只需改 Token.activeSkin。

enum SkinID: String, CaseIterable {
    case champagne   // 香槟银 Discman（初版）
    case graphite    // 石墨黑 + 琥珀 LCD
    case bone        // 80s 米白塑料 + 黄绿 LCD
    case steel       // 拉丝钢 Hi-Fi + 荧光绿 LCD

    var displayName: String {
        switch self {
        case .champagne: return "香槟银"
        case .graphite: return "石墨黑"
        case .bone: return "白色塑料"
        case .steel: return "拉丝钢"
        }
    }
}

struct SkinPalette {
    var bodyTop: Color
    var bodyMid: Color
    var bodyBottom: Color
    var bodyRimLight: Color
    var bodyRimDark: Color
    var bodyEdgeShadow: Color
    var silkscreenInk: Color
    var bodyShadow: Color
    var brushed: Bool
    var lidTop: Color
    var lidBottom: Color

    var discBase: Color
    var discInner: Color
    var discEdge: Color
    var discHub: Color
    var discSilkscreen: Color
    var iridescentWashAlpha: Double
    var iridescentBandAlpha: Double

    var lcdTop: Color
    var lcdBottom: Color
    var lcdText: Color
    var lcdBezel: Color
    var lcdGlow: Color

    var keyTop: Color
    var keyBottom: Color
    var keyRim: Color
    var stickerPaper: Color
    var stickerInk: Color
    var stickerEdge: Color
}

enum SkinLibrary {

    static func palette(for skin: SkinID) -> SkinPalette {
        switch skin {
        case .champagne:
            return SkinPalette(
                bodyTop: Color(hex: 0xF8F2E8),
                bodyMid: Color(hex: 0xD3C8B4),
                bodyBottom: Color(hex: 0xAFA28C),
                bodyRimLight: Color(hex: 0xF2EADA),
                bodyRimDark: Color(hex: 0x8A7D68),
                bodyEdgeShadow: Color(hex: 0x8E8271),
                silkscreenInk: Color(hex: 0x6E6353),
                bodyShadow: Color(hex: 0x8B7C68),
                brushed: false,
                lidTop: Color(hex: 0xF3ECE0),
                lidBottom: Color(hex: 0xDCD2C0),
                discBase: Color(hex: 0xE4E8EC),
                discInner: Color(hex: 0x9AA2AD),
                discEdge: Color(hex: 0x767D88),
                discHub: Color(hex: 0x8F959E),
                discSilkscreen: Color(hex: 0x575C63),
                iridescentWashAlpha: 0.10,
                iridescentBandAlpha: 0.42,
                lcdTop: Color(hex: 0x0B2A38),
                lcdBottom: Color(hex: 0x061A24),
                lcdText: Color(hex: 0x7FD8FF),
                lcdBezel: Color(hex: 0x17161A),
                lcdGlow: Color(hex: 0x4FC8F5),
                keyTop: Color(hex: 0xE4DBCB),
                keyBottom: Color(hex: 0xC6BAA6),
                keyRim: Color(hex: 0x8E8271),
                stickerPaper: Color(hex: 0xF2EADA),
                stickerInk: Color(hex: 0x35322C),
                stickerEdge: Color(hex: 0xD8CDB9)
            )

        case .graphite:
            // 90 年代黑色 Discman：哑光黑机身、琥珀点阵屏、按键浅一档好辨认
            return SkinPalette(
                bodyTop: Color(hex: 0x45454A),
                bodyMid: Color(hex: 0x35353A),
                bodyBottom: Color(hex: 0x1E1E22),
                bodyRimLight: Color(hex: 0x7C7C84),
                bodyRimDark: Color(hex: 0x141416),
                bodyEdgeShadow: Color(hex: 0x101012),
                silkscreenInk: Color(hex: 0x9A9AA2),
                bodyShadow: Color(hex: 0x0E0E10),
                brushed: false,
                lidTop: Color(hex: 0x4C4C52),
                lidBottom: Color(hex: 0x26262A),
                discBase: Color(hex: 0xDCE1E7),
                discInner: Color(hex: 0x8C939C),
                discEdge: Color(hex: 0x5E646D),
                discHub: Color(hex: 0x7C828B),
                discSilkscreen: Color(hex: 0x3C4046),
                iridescentWashAlpha: 0.08,
                iridescentBandAlpha: 0.34,
                lcdTop: Color(hex: 0x1E1206),
                lcdBottom: Color(hex: 0x0C0703),
                lcdText: Color(hex: 0xFFAE3C),
                lcdBezel: Color(hex: 0x0B0B0D),
                lcdGlow: Color(hex: 0xFF9A1F),
                keyTop: Color(hex: 0x5A5A61),
                keyBottom: Color(hex: 0x33333A),
                keyRim: Color(hex: 0x8C8C94),
                stickerPaper: Color(hex: 0xE6E1D6),
                stickerInk: Color(hex: 0x1C1C1E),
                stickerEdge: Color(hex: 0xBEB7A8)
            )

        case .bone:
            // 80 年代米白塑料：暖白机身、黄绿 LCD、按键比机身深一档
            return SkinPalette(
                bodyTop: Color(hex: 0xF8F6EF),
                bodyMid: Color(hex: 0xEBE7DC),
                bodyBottom: Color(hex: 0xD3CCBD),
                bodyRimLight: Color(hex: 0xFFFFFF),
                bodyRimDark: Color(hex: 0xB4AC9C),
                bodyEdgeShadow: Color(hex: 0xA79E8E),
                silkscreenInk: Color(hex: 0x7C7466),
                bodyShadow: Color(hex: 0x9A9182),
                brushed: false,
                lidTop: Color(hex: 0xF5F2E9),
                lidBottom: Color(hex: 0xDED8CA),
                discBase: Color(hex: 0xE6E9EC),
                discInner: Color(hex: 0x9CA3AC),
                discEdge: Color(hex: 0x777E87),
                discHub: Color(hex: 0x8D939C),
                discSilkscreen: Color(hex: 0x4F5450),
                iridescentWashAlpha: 0.11,
                iridescentBandAlpha: 0.46,
                lcdTop: Color(hex: 0x1B2410),
                lcdBottom: Color(hex: 0x0B1307),
                lcdText: Color(hex: 0xB6E85C),
                lcdBezel: Color(hex: 0x15140F),
                lcdGlow: Color(hex: 0x9BD642),
                keyTop: Color(hex: 0xF5F2E8),
                keyBottom: Color(hex: 0xD8D2C3),
                keyRim: Color(hex: 0xAAA292),
                stickerPaper: Color(hex: 0xFBF8F1),
                stickerInk: Color(hex: 0x3A382F),
                stickerEdge: Color(hex: 0xCCC5B4)
            )

        case .steel:
            // 台式 Hi-Fi：冷灰拉丝钢、荧光绿 VFD、按键与机身同色但更亮
            return SkinPalette(
                bodyTop: Color(hex: 0xD3D7DA),
                bodyMid: Color(hex: 0xB3B8BC),
                bodyBottom: Color(hex: 0x84898E),
                bodyRimLight: Color(hex: 0xEDF1F3),
                bodyRimDark: Color(hex: 0x5C6166),
                bodyEdgeShadow: Color(hex: 0x55595E),
                silkscreenInk: Color(hex: 0x4E545A),
                bodyShadow: Color(hex: 0x4A4E52),
                brushed: true,
                lidTop: Color(hex: 0xDCE0E3),
                lidBottom: Color(hex: 0xA0A5AA),
                discBase: Color(hex: 0xE8EBEE),
                discInner: Color(hex: 0x969DA5),
                discEdge: Color(hex: 0x6A7078),
                discHub: Color(hex: 0x828992),
                discSilkscreen: Color(hex: 0x3E444A),
                iridescentWashAlpha: 0.09,
                iridescentBandAlpha: 0.38,
                lcdTop: Color(hex: 0x07120F),
                lcdBottom: Color(hex: 0x030A08),
                lcdText: Color(hex: 0x6FE8B8),
                lcdBezel: Color(hex: 0x101214),
                lcdGlow: Color(hex: 0x3FD79E),
                keyTop: Color(hex: 0xC8CCD0),
                keyBottom: Color(hex: 0x999EA3),
                keyRim: Color(hex: 0x6E7378),
                stickerPaper: Color(hex: 0xE9EAEC),
                stickerInk: Color(hex: 0x2A2E31),
                stickerEdge: Color(hex: 0xB8BDC1)
            )
        }
    }
}

enum Token {

    // MARK: 当前皮肤

    /// 全局皮肤。切换后下一次绘制即生效（所有颜色都是计算属性）。
    nonisolated(unsafe) static var activeSkin: SkinID = .champagne

    private static var p: SkinPalette { SkinLibrary.palette(for: activeSkin) }

    // MARK: 几何

    static let windowSize: CGFloat = 344      // 含 12pt 投影留白
    static let bodySize: CGFloat = 320
    static let bodyRadius: CGFloat = 28
    static let bodyMargin: CGFloat = 12

    static let lidPlateDiameter: CGFloat = 216

    static let discDiameter: CGFloat = 200
    static let discCenter = CGPoint(x: 148, y: 132)
    static let lidRingDiameter: CGFloat = 216
    static let hubDiameter: CGFloat = 44
    static let holeDiameter: CGFloat = 14
    static let discRingDiameters: [CGFloat] = [60, 110, 150]
    static let discSilkscreenRadius: CGFloat = 84

    static let lcdSize = CGSize(width: 176, height: 32)
    static let lcdOrigin = CGPoint(x: 16, y: 254)
    static let lcdRadius: CGFloat = 4
    static let lcdStatusWidth: CGFloat = 18
    static let lcdTextWidth: CGFloat = 150

    static let keyDiameter: CGFloat = 22
    /// 命中热区：可见仍是 Ø22，点击判定用 Ø38（见 visual-spec §6）
    static let keyHitDiameter: CGFloat = 38
    static let keyY: CGFloat = 272
    static let keyCentersX: [CGFloat] = [216, 248, 280]

    static let stickerDiameter: CGFloat = 38
    static let stickerCenter = CGPoint(x: 268, y: 46)
    static let stickerRotation: Double = -7

    static let silkscreenBaselineY: CGFloat = 244

    // MARK: 颜色 · 机身

    static var bodyTop: Color { p.bodyTop }
    static var bodyMid: Color { p.bodyMid }
    static var bodyBottom: Color { p.bodyBottom }
    static var bodyRimLight: Color { p.bodyRimLight }
    static var bodyRimDark: Color { p.bodyRimDark }
    static var bodyEdgeShadow: Color { p.bodyEdgeShadow }
    static var silkscreenInk: Color { p.silkscreenInk }
    static var bodyShadow: Color { p.bodyShadow }

    /// 拉丝质感：横向细密条纹，只有金属皮肤开启
    static var hasBrushedTexture: Bool { p.brushed }
    static var brushedTexture: LinearGradient {
        var stops: [Gradient.Stop] = []
        let count = 96
        for i in 0...count {
            stops.append(.init(
                color: Color.white.opacity(i % 2 == 0 ? 0.045 : 0.0),
                location: Double(i) / Double(count)
            ))
        }
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    static var lidTop: Color { p.lidTop }
    static var lidBottom: Color { p.lidBottom }

    // MARK: 颜色 · 碟片

    static var discBase: Color { p.discBase }
    static var discInner: Color { p.discInner }
    static var discEdge: Color { p.discEdge }
    static var discHub: Color { p.discHub }
    static var discHole = Color(hex: 0x232427)
    static var discSilkscreen: Color { p.discSilkscreen }

    static let iridescentPink = Color(hex: 0xE8B7C8)
    static let iridescentGold = Color(hex: 0xE7D9A8)
    static let iridescentMint = Color(hex: 0xBFE8D7)
    static let iridescentSky = Color(hex: 0xBFD6EA)
    static let iridescentAlpha: Double = 0.30
    static var iridescentWashAlpha: Double { p.iridescentWashAlpha }
    static var iridescentBandAlpha: Double { p.iridescentBandAlpha }
    static let iridescentBandWidth: CGFloat = 26
    static let iridescentBandDiameter: CGFloat = 158
    static let discGlareAlpha: Double = 0.16
    static let discGlareWidth: CGFloat = 44
    static let discGlareAngle: Double = -27

    // 真实封面印到碟面时的处理：压低饱和度 + 盖一层薄雾，避免原图太亮把彩虹带吃掉
    static let discArtworkSaturation: Double = 0.92
    static let discArtworkVeil: Double = 0.10

    // MARK: 颜色 · LCD

    static var lcdTop: Color { p.lcdTop }
    static var lcdBottom: Color { p.lcdBottom }
    static var lcdText: Color { p.lcdText }
    static var lcdTextDim: Color { p.lcdText.opacity(0.45) }
    static var lcdBezel: Color { p.lcdBezel }
    static var lcdGlow: Color { p.lcdGlow }

    // MARK: 颜色 · 按键与贴纸

    static var keyTop: Color { p.keyTop }
    static var keyBottom: Color { p.keyBottom }
    static var keyRim: Color { p.keyRim }
    static var stickerPaper: Color { p.stickerPaper }
    static var stickerInk: Color { p.stickerInk }
    static var stickerEdge: Color { p.stickerEdge }

    // MARK: 排版

    static let lcdFontSize: CGFloat = 11
    static let lcdTracking: CGFloat = 0.6
    static let lcdStatusFontSize: CGFloat = 9
    static let silkscreenFontSize: CGFloat = 6
    static let silkscreenTracking: CGFloat = 2.6
    static let discRingFontSize: CGFloat = 6
    static let discRingTracking: CGFloat = 2.4
    static let stickerFontSize: CGFloat = 6
    static let stickerSubFontSize: CGFloat = 4.5
    static let stickerTracking: CGFloat = 0.8
    static let stickerSubTracking: CGFloat = 1.4

    static var lcdFont: Font {
        .system(size: lcdFontSize, weight: .medium, design: .monospaced)
    }
    static var lcdStatusFont: Font {
        .system(size: lcdStatusFontSize, weight: .regular, design: .monospaced)
    }

    // MARK: 动效

    static let discRevolution: Double = 8.0   // 秒 / 圈
    static let spinUpDuration: Double = 0.8
    static let spinDownDuration: Double = 2.2
    static let marqueeSpeed: Double = 34      // pt/s
    static let marqueeHold: Double = 0.9
    static let marqueeGapRatio: CGFloat = 0.75  // 首尾空白 = 可视宽度 × 该比例
    static let lcdTextFade: Double = 0.12
    static let idleDim: Double = 0.35

    // MARK: LCD 文案

    /// 无曲名时的跑马灯文案。想改成"留空"只需把这里置为空串。
    static let lcdFallbackPlaying = "NETEASE · PLAYING"
    static let lcdPaused = "PAUSE"
    static let lcdIdle = "STANDBY"
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}
