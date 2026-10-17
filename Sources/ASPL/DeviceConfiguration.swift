//
//  DeviceConfiguration.swift
//  ASPL
//
//  Created by Bonjour, LLC on 2026/10/17.
//

public struct DeviceConfiguration: Sendable {
    public enum SampleFormat: Sendable {
        case int16
        case float32
    }

    public enum StreamDirection: Sendable {
        /// Audio that client apps read from the virtual device.
        case input
        /// Audio that client apps write to the virtual device.
        case output
    }

    public let name: String
    public let manufacturer: String
    public let uid: String
    public let sampleRate: UInt32
    public let channelCount: UInt32
    public let streams: Set<StreamDirection>
    public let sampleFormat: SampleFormat

    /// Streams use interleaved native-endian PCM.
    public init(
        name: String,
        manufacturer: String,
        uid: String,
        sampleRate: UInt32,
        channelCount: UInt32,
        streams: Set<StreamDirection>,
        sampleFormat: SampleFormat = .int16
    ) {
        self.name = name
        self.manufacturer = manufacturer
        self.uid = uid
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.streams = streams
        self.sampleFormat = sampleFormat
    }
}
