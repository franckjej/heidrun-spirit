// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "heidrun-spirit",
    platforms: [.macOS(.v15)],
    dependencies: [
        // `exact:` (not `from:`) because pre-release SemVer strings
        // compare lexically — `from: "1.0.0-rcN"` will happily pick
        // a lower-numbered rc as "newer". See `feedback_spm_prerelease_pin`
        // in the heidrun-swift session memory for the rabbit hole.
        .package(url: "https://github.com/franckjej/heidrun-protocol.git", exact: "1.0.0-rc17")
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
        .executableTarget(
            name: "heidrun-spirit",
            dependencies: [
                "SpiritKit",
                .product(name: "HeidrunNIOClient", package: "heidrun-protocol")
            ]
        ),
        .testTarget(name: "SpiritKitTests", dependencies: ["SpiritKit"])
    ]
)
