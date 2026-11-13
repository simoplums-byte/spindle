import SwiftUI

/// 把整机渲染成 PNG，供评审与文档使用。不依赖屏幕截图，背景由代码决定。
struct RenderSheet: View {
    let model: RotationModel
    var state: NowPlaying = {
        var s = NowPlaying()
        s.status = .playing
        s.source = .netease
        return s
    }()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xEDE9E2), Color(hex: 0xDCD6CB)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            BodyView(rotation: model, nowPlaying: state)
                .frame(width: Token.bodySize, height: Token.bodySize)
        }
        .frame(width: Token.windowSize, height: Token.windowSize)
    }
}
