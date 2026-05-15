// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "DSPlay",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "DSPlay", targets: ["DSPlay"])
    ],
    targets: [
        .executableTarget(
            name: "DSPlay",
            path: "DSPlay",
            exclude: ["Tests"],
            resources: [
                .copy("Resources/WebDist"),
                .copy("Resources/StatusItem.png"),
            ]
        ),
        .testTarget(
            name: "DSPlayTests",
            dependencies: ["DSPlay"],
            path: "DSPlay/Tests",
            swiftSettings: [
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-disable-cross-import-overlays",
                ])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-framework", "Testing",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                ])
            ]
        ),
    ]
)
