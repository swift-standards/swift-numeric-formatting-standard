// swift-tools-version: 6.2

import PackageDescription

// Numeric Formatting Standard
//
// Foundation-free numeric formatting implementation supporting:
// - Integer and floating-point formatting
// - Precision control (fraction length, significant digits, integer length)
// - Notation styles (automatic, compact, scientific)
// - Sign display strategies
// - Grouping separators
// - Decimal separator configuration
// - Scale transformations
// - Rounding rules and increments
//
// Pure Swift implementation with no Foundation dependencies,
// suitable for Swift Embedded and constrained environments.
// Uses ISO 9899 (C Standard Library Math) for O(1) hardware-accelerated power operations.

let package = Package(
    name: "swift-numeric-formatting-standard",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Numeric Formatting",
            targets: ["Numeric Formatting"]
        )
    ],
    dependencies: [
        .package(path: "../swift-standards"),
        .package(path: "../swift-svg-standard"),
        .package(path: "../swift-iso-9899"),
    ],
    targets: [
        .target(
            name: "Numeric Formatting",
            dependencies: [
                .product(name: "Standards", package: "swift-standards"),
                .product(name: "Formatting", package: "swift-standards"),
                .product(name: "ISO 9899", package: "swift-iso-9899"),
            ]
        ),
        .testTarget(
            name: "Numeric Formatting".tests,
            dependencies: [
                "Numeric Formatting",
                .product(name: "StandardsTestSupport", package: "swift-standards"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings =
        existing + [
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
        ]
}
