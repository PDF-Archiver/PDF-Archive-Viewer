// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ArchiveCore",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
//        .library(name: "ArchiveCore", targets: ["ArchiveCore"]),
        .library(name: "ArchiveBackend", targets: ["ArchiveBackend"]),
        .library(name: "ArchiveViews", targets: ["ArchiveViews"]),
        .library(name: "ArchiveSharedConstants", targets: ["ArchiveSharedConstants"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/PDF-Archiver/LoggingKit", from: "1.0.0"),
        .package(url: "https://github.com/onmyway133/DeepDiff.git", from: "2.3.1"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX", from: "0.0.3"),
        .package(url: "https://github.com/dasautoooo/Parma", from: "0.1.1"),
        .package(url: "https://github.com/WeTransfer/Diagnostics", from: "1.7.0"),
        .package(url: "https://github.com/bizz84/SwiftyStoreKit", from: "0.16.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
//        .target(name: "ArchiveCore", dependencies: ["ArchiveBackend", "ArchiveViews"]),
        .target(
            name: "ArchiveBackend",
            dependencies: [
                "ArchiveSharedConstants",
                .product(name: "Logging", package: "swift-log"),
                "LoggingKit",
                "DeepDiff"
            ]),
        .target(name: "ArchiveViews", dependencies: ["ArchiveBackend", "ArchiveSharedConstants", "SwiftyStoreKit", "SwiftUIX", "LoggingKit", "Parma", "Diagnostics"]),
        .target(name: "ArchiveSharedConstants", dependencies: ["LoggingKit"]),
        .testTarget(
            name: "ArchiveBackendTests",
            dependencies: ["ArchiveBackend"])
    ]
)
