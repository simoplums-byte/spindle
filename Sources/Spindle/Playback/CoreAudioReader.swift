import AppKit
import CoreAudio

/// 直接读 HAL 的进程音频活动。零权限、零轮询开销之外的副作用。
enum CoreAudioReader {

    struct AudioProcess {
        let pid: pid_t
        let bundleID: String?
        let name: String?
        let execPath: String
        let isRunning: Bool
    }

    private static let systemObject = AudioObjectID(kAudioObjectSystemObject)

    /// 当前出现在 HAL 进程列表里的所有进程。
    static func processes() -> [AudioProcess] {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(systemObject, &addr, 0, nil, &size) == noErr, size > 0 else {
            return []
        }
        let count = Int(size) / MemoryLayout<AudioObjectID>.size
        var objects = [AudioObjectID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(systemObject, &addr, 0, nil, &size, &objects) == noErr else {
            return []
        }

        return objects.compactMap { object in
            guard let pid = pid(of: object) else { return nil }
            guard pid > 0 else { return nil }
            let app = NSRunningApplication(processIdentifier: pid)
            return AudioProcess(
                pid: pid,
                bundleID: app?.bundleIdentifier,
                name: app?.localizedName,
                execPath: execPath(pid),
                isRunning: (readUInt32(object, kAudioProcessPropertyIsRunning) ?? 0) == 1
            )
        }
    }

    /// 辅助进程（如 Chrome 的 Aperitif）没有 App 包装，NSRunningApplication 查不到，
    /// 只能靠可执行路径认人。
    private static func execPath(_ pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: 4096)
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return "" }
        return String(cString: buffer)
    }

    private static func pid(of object: AudioObjectID) -> pid_t? {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyPID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<pid_t>.size)
        var value: pid_t = 0
        return AudioObjectGetPropertyData(object, &addr, 0, nil, &size, &value) == noErr ? value : nil
    }

    private static func readUInt32(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> UInt32? {
        var addr = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<UInt32>.size)
        var value: UInt32 = 0
        return AudioObjectGetPropertyData(object, &addr, 0, nil, &size, &value) == noErr ? value : nil
    }
}
