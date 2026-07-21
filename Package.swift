// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Firma",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "Firma",
            targets: ["Firma"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "602.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections.git", from: "1.1.1"),
    ],
    targets: [
        .target(
            name: "Firma",
            dependencies: [
                "FormModelMacros",
                .product(name: "IdentifiedCollections", package: "swift-identified-collections")
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .testTarget(
            name: "FirmaTests",
            dependencies: [
                "Firma"
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .target(
            name: "FirmaClientFixture",
            dependencies: ["Firma"],
            path: "Tests/FirmaClientFixture",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .testTarget(
            name: "FirmaClientTests",
            dependencies: ["Firma", "FirmaClientFixture"],
            path: "Tests/FirmaClientTests",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .macro(
            name: "FormModelMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
        ),
        .testTarget(
            name: "FormModelMacroTests",
            dependencies: [
                "FormModelMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            path: "Tests/FormModelMacroTests"
        ),
    ]
)
