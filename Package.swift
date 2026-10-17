// swift-tools-version: 5.9
//
//  Package.swift
//  libASPL
//
//  Created by Bonjour, LLC on 2026/10/17.
//

import PackageDescription

let package = Package(
    name: "libASPL",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "libASPL", type: .static, targets: ["libASPL"]),
    ],
    targets: [
        .target(
            name: "libASPL",
            path: ".",
            exclude: [
                "src/Bridge.json",
                "src/Device.json",
                "src/MuteControl.json",
                "src/Object.json",
                "src/Plugin.json",
                "src/Stream.json",
                "src/VolumeControl.json",
            ],
            sources: ["src"],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("CoreFoundation"),
            ]
        ),
    ],
    cxxLanguageStandard: .cxx17
)
