// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KikoCursor",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "KikoCore", path: "Sources/KikoCore"),
        .executableTarget(name: "KikoCursor", dependencies: ["KikoCore"], path: "Sources/KikoCursor"),
    ]
)
