// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FineVolume",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "FineVolume", targets: ["FineVolume"]),
    ],
    targets: [
        .target(
            name: "FineVolumeCore",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ],
            linkerSettings: [
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreAudio"),
            ]
        ),
        .executableTarget(
            name: "FineVolume",
            dependencies: ["FineVolumeCore"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .executableTarget(
            name: "FineVolumeCoreChecks",
            dependencies: ["FineVolumeCore"],
            path: "Checks/FineVolumeCoreChecks",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
    ]
)
