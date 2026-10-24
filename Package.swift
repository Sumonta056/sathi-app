// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Sathi",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0")
    ],
    targets: [
        .target(name: "SathiCore", path: "Sources/SathiCore"),
        .target(name: "SathiUI", dependencies: ["SathiCore"], path: "Sources/SathiUI"),
        .executableTarget(name: "Sathi", dependencies: ["SathiCore", "SathiUI"], path: "Sources/Sathi"),
        .target(name: "SathiTestSupport", dependencies: ["SathiCore"], path: "Tests/SathiTestSupport"),
        .testTarget(
            name: "SathiCoreTests",
            dependencies: ["SathiCore", "SathiTestSupport"],
            path: "Tests/SathiCoreTests"
        ),
        .testTarget(
            name: "SathiUITests",
            dependencies: ["SathiCore", "SathiUI", "SathiTestSupport", "ViewInspector"],
            path: "Tests/SathiUITests"
        )
    ]
)
