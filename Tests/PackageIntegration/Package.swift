// swift-tools-version: 5.9
//
//  Package.swift
//  ASPLIntegration
//
//  Created by Bonjour, LLC on 2026/10/17.
//

import PackageDescription

let package = Package(
    name: "ASPLIntegration",
    platforms: [.macOS("26.0")],
    dependencies: [.package(path: "../..")],
    targets: [
        .executableTarget(
            name: "SwiftConsumer",
            dependencies: [.product(name: "ASPL", package: "libASPL")]
        ),
        .executableTarget(
            name: "CxxConsumer",
            dependencies: [.product(name: "libASPL", package: "libASPL")]
        ),
    ],
    cxxLanguageStandard: .cxx17
)
