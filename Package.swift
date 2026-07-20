// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Formulaire",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "Formulaire",
            targets: ["Formulaire"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "602.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections.git", from: "1.1.1"),
    ],
    targets: [
        .target(
            name: "Formulaire",
            dependencies: [
                "FormulaireMacros",
                .product(name: "IdentifiedCollections", package: "swift-identified-collections")
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .testTarget(
            name: "FormulaireTests",
            dependencies: [
                "Formulaire"
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .target(
            name: "FormulaireClientFixture",
            dependencies: ["Formulaire"],
            path: "Tests/FormulaireClientFixture",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .testTarget(
            name: "FormulaireClientTests",
            dependencies: ["Formulaire", "FormulaireClientFixture"],
            path: "Tests/FormulaireClientTests",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .macro(
            name: "FormulaireMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
        ),
        .testTarget(
            name: "FormulaireMacroTests",
            dependencies: [
                "FormulaireMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            path: "Tests/FormulaireMacroTests"
        ),
    ]
)
