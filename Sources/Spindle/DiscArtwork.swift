import AppKit

/// 碟面用的位图素材。打包进 .app 的 Resources，开发期从 .build 直接跑也能找到。
enum DiscArtwork {
    static let jibuli: NSImage? = load("disc-jibuli")

    private static func load(_ name: String) -> NSImage? {
        var candidates: [URL] = []
        if let bundled = Bundle.main.url(forResource: name, withExtension: "png") {
            candidates.append(bundled)
        }

        // 从可执行文件往上找 Assets/，覆盖 .build/release 与 .app/Contents/MacOS 两种位置
        let executable = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        var directory = executable.deletingLastPathComponent()
        for _ in 0..<5 {
            candidates.append(directory.appendingPathComponent("Assets/\(name).png"))
            directory = directory.deletingLastPathComponent()
        }
        candidates.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Assets/\(name).png"))

        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            if let image = NSImage(contentsOf: url) {
                return image
            }
        }
        FileHandle.standardError.write("missing artwork \(name).png\n".data(using: .utf8)!)
        return nil
    }
}
