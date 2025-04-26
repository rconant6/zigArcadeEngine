// swift-tools-version: 6.1
import PackageDescription
// expected 'name:dependencies:path:exclude:sources:resources:publicHeadersPath:packageAccess:cSettings:cxxSettings:swiftSettings:linkerSettings:plugins:')
let package = Package(
    name: "Bridge",
    products: [
        .library(
            name: "Bridge", 
            type: .dynamic, 
            targets: ["KeyboardBridge", "WindowBridge"],
        ),
    ],
    targets: [
        .target(
            name: "CKeyboardBridge",
            path: "Sources/CBridge/kb",
            publicHeadersPath: "include/",
        ),
        .target(
            name: "KeyboardBridge",
            dependencies: ["CKeyboardBridge"],
            path: "Sources/SwiftBridge/kb",
        ),
        .target(
            name: "CWindowBridge",
            path: "Sources/CBridge/w",
            publicHeadersPath: "include/",
        ),
        .target(
            name: "WindowBridge",
            dependencies: ["CWindowBridge"],
            path: "Sources/SwiftBridge/w",
        ),    
    ]
)
