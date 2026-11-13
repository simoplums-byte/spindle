// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Spindle",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Spindle", targets: ["Spindle"])
    ],
    targets: [
        .executableTarget(
            name: "Spindle",
            path: "Sources/Spindle"
        )
    ]
)
