// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "heidrun-spirit",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "git@github.com:franckjej/heidrun-protocol.git", from: "1.0.0-rc7")
    ],
    targets: [
        // 2001 MegaHAL C, reused verbatim. `-std=gnu89` for the K&R source;
        // `-w` silences its warnings; `-UDEBUG` because SwiftPM defines DEBUG
        // in debug builds, which would pull the dropped `debug.h`.
        .target(
            name: "CMegaHAL",
            cSettings: [.unsafeFlags(["-std=gnu89", "-w", "-UDEBUG"])]
        ),
        .target(
            name: "SpiritKit",
            dependencies: [
                "CMegaHAL",
                .product(name: "HeidrunCore", package: "heidrun-protocol")
            ],
            resources: [.copy("Resources/brain")]
        ),
        .executableTarget(name: "heidrun-spirit", dependencies: ["SpiritKit"]),
        .testTarget(name: "SpiritKitTests", dependencies: ["SpiritKit"])
    ]
)
