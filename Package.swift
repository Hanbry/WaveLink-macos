// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "WaveLink",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WaveLink",
            targets: ["WaveLink"]),
    ],
    dependencies: [
        .package(url: "https://github.com/armadsen/ORSSerialPort.git", from: "2.1.0")
    ],
    targets: [
        .target(
            name: "WaveLink",
            dependencies: ["ORSSerialPort"]),
        .testTarget(
            name: "WaveLinkTests",
            dependencies: ["WaveLink"]),
    ]
) 