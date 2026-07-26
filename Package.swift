// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyboardCleaner",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "KeyboardCleaner", targets: ["KeyboardCleaner"])
    ],
    targets: [
        .executableTarget(
            name: "KeyboardCleaner",
            path: "Sources/KeyboardCleaner",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
