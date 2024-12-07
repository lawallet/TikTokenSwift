// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TikTokenSwift",
    platforms: [.iOS(.v13), .macOS(.v13), .tvOS(.v16), .visionOS(.v1), .watchOS(.v6)],
    products: [
        .library(name: "TikTokenSwift", targets: ["TikTokenSwift"]),
    ],
    targets: [
        .target(name: "TikTokenSwift"),
        .testTarget(name: "TikTokenSwiftTests", dependencies: ["TikTokenSwift"]),
    ]
)
