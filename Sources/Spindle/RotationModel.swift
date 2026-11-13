import Foundation
import SwiftUI

/// 碟片角度的唯一状态源。
/// 只有播放时按角速度累加，暂停时角速度指数衰减到 0，停在该时刻的角度，不做归位。
@MainActor
final class RotationModel: ObservableObject {

    @Published private(set) var angle: Double = 0   // 度，0..<360
    @Published private(set) var isPlaying: Bool = false

    private var speed: Double = 0                  // 圈 / 秒
    private var timer: Timer?
    private var lastTick = Date()

    func setPlaying(_ playing: Bool) {
        guard isPlaying != playing else { return }
        isPlaying = playing
        startTickingIfNeeded()
    }

    func toggle() {
        setPlaying(!isPlaying)
    }

    private func startTickingIfNeeded() {
        guard timer == nil else { return }
        lastTick = Date()
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        let now = Date()
        let dt = min(now.timeIntervalSince(lastTick), 0.25)
        lastTick = now

        let target: Double = isPlaying ? 1.0 / Token.discRevolution : 0
        let tau: Double = max(isPlaying ? Token.spinUpDuration : Token.spinDownDuration, 0.05) / 3.0
        speed += (target - speed) * (1 - exp(-dt / tau))

        guard abs(speed) > 0.0001 else { return }
        angle = (angle + speed * 360.0 * dt).truncatingRemainder(dividingBy: 360)
        if angle < 0 { angle += 360 }
    }
}
