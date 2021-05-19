// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CreditCardReader",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CreditCardReader-SwiftUI",
            targets: ["CreditCardReader-View", "CreditCardReader-Model", "CreditCardReader-SwiftUI"]),
        .library(
            name: "CreditCardReader-AltSwiftUI",
            targets: ["CreditCardReader-View", "CreditCardReader-Model", "CreditCardReader-AltSwiftUI"]),
        .library(
            name: "CreditCardReader-UIKit",
            targets: ["CreditCardReader-View", "CreditCardReader-Model", "CreditCardReader-UIKit"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/rakutentech/AltSwiftUI", from: "1.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CreditCardReader-View",
            dependencies: [],
            path: "Sources/Views"),
        .target(
            name: "CreditCardReader-Model",
            dependencies: [],
            path: "Sources/Model"),
        .target(
            name: "CreditCardReader-SwiftUI",
            dependencies: [],
            path: "Sources/SwiftUI"),
        .target(
            name: "CreditCardReader-AltSwiftUI",
            dependencies: ["AltSwiftUI"],
            path: "Sources/AltSwiftUI"),
        .target(
            name: "CreditCardReader-UIKit",
            dependencies: [],
            path: "Sources/UIKit")
    ],
    swiftLanguageVersions: [SwiftVersion.v5]
)
