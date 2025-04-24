// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "KeyboardBridge",
    products: [
        .library(
            name: "KeyboardBridge", 
            type: .dynamic, 
            targets: ["KeyboardBridge"],
        ),
    ],
    targets: [
        .target(
            name: "CKeyboardBridge",
            path: "Sources/CkbBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "KeyboardBridge",
            dependencies: ["CKeyboardBridge"],
            path: "Sources/KeyboardBridge"
        )
    ]
)
