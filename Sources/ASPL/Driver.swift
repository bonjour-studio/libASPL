//
//  Driver.swift
//  ASPL
//
//  Created by Bonjour, LLC on 2026/10/17.
//

import ASPLBridge
import CoreAudio

/// Owns a libASPL driver and its single virtual device.
/// Creating this object does not install or register a device with macOS.
public final class Driver {
    public enum CreationError: Error {
        case invalidConfiguration
        case constructionFailed
    }

    private let handle: OpaquePointer

    public init(configuration: DeviceConfiguration) throws {
        guard !configuration.name.isEmpty,
              !configuration.uid.isEmpty,
              ![configuration.name, configuration.manufacturer, configuration.uid]
                .contains(where: { $0.utf8.contains(0) }),
              configuration.sampleRate > 0,
              configuration.channelCount > 0,
              configuration.channelCount <= UInt32.max / UInt32(MemoryLayout<Int16>.size),
              !configuration.streams.isEmpty else {
            throw CreationError.invalidConfiguration
        }

        guard let handle = ASPLDriverCreate(
            configuration.name,
            configuration.manufacturer,
            configuration.uid,
            configuration.sampleRate,
            configuration.channelCount,
            configuration.streams.contains(.input),
            configuration.streams.contains(.output)
        ) else {
            throw CreationError.constructionFailed
        }
        self.handle = handle
    }

    deinit {
        ASPLDriverDestroy(handle)
    }

    /// Return this reference from the driver's HAL factory after checking its type UUID.
    /// Keep this `Driver` alive for as long as HAL may access the reference.
    public var reference: AudioServerPlugInDriverRef {
        ASPLDriverGetReference(handle)
    }
}
