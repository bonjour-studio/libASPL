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

    public init(configuration: DeviceConfiguration, ioHandler: IOHandler = IOHandler(), properties: [DeviceProperty] = []) throws {
        let sampleSize: UInt32 = configuration.sampleFormat == .float32 ? 4 : 2
        guard !configuration.name.isEmpty,
              !configuration.uid.isEmpty,
              ![configuration.name, configuration.manufacturer, configuration.uid]
                .contains(where: { $0.utf8.contains(0) }),
              configuration.sampleRate > 0,
              configuration.channelCount > 0,
              configuration.channelCount <= UInt32.max / sampleSize,
              !configuration.streams.isEmpty,
              Set(properties.map(\.selector)).count == properties.count else {
            throw CreationError.invalidConfiguration
        }

        let callbacks = properties.map {
            ASPLPropertyCallbacks(selector: $0.selector, context: $0.context, copyValue: $0.copyValue, setValue: $0.setValue)
        }
        let created = callbacks.withUnsafeBufferPointer { properties in
            ASPLDriverCreate(
                configuration.name,
                configuration.manufacturer,
                configuration.uid,
                configuration.sampleRate,
                configuration.channelCount,
                configuration.streams.contains(.input),
                configuration.streams.contains(.output),
                configuration.sampleFormat == .float32,
                ASPLIOCallbacks(context: ioHandler.context, read: ioHandler.read, write: ioHandler.write, reset: ioHandler.reset),
                properties.baseAddress, UInt32(properties.count)
            )
        }
        guard let handle = created else {
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
