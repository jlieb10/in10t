// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Intentional",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "IntentionalCore",
            targets: ["IntentionalCore"]),
    ],
    dependencies: [
        // Firebase
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        // Google Sign-In
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "IntentionalCore",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ],
            path: "Sources/Core"
        ),
        .testTarget(
            name: "IntentionalCoreTests",
            dependencies: ["IntentionalCore"],
            path: "Tests/Unit"
        ),
    ]
)