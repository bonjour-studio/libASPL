//
//  main.swift
//  SwiftConsumer
//
//  Created by Bonjour, LLC on 2026/10/17.
//

import ASPL

let driver = try Driver(configuration: DeviceConfiguration(
    name: "Standalone Swift Consumer",
    manufacturer: "Example Manufacturer",
    uid: "com.example.aspl.swift-consumer",
    sampleRate: 48000,
    channelCount: 1,
    streams: [.input, .output]
))
withExtendedLifetime(driver) {
    precondition(driver.reference.pointee != nil)
    print("Swift consumer passed without C++ interoperability settings")
}
