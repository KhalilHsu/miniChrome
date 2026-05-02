// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "PeekLink",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PeekLink", targets: ["PeekLink"]),
        .executable(name: "PeekLinkHost", targets: ["PeekLinkHost"]),
    ],
    targets: [
        .executableTarget(
            name: "PeekLink",
            dependencies: [],
            path: "Sources/PeekLink"
        ),
        .executableTarget(
            name: "PeekLinkHost",
            dependencies: [],
            path: "Sources/PeekLinkHost"
        ),
    ]
)
