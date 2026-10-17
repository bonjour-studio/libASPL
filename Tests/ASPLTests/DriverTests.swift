//
//  DriverTests.swift
//  ASPLTests
//
//  Created by Bonjour, LLC on 2026/10/17.
//

import ASPL
import CoreAudio
import Testing

struct DriverTests {
    @Test(arguments: [
        Set<DeviceConfiguration.StreamDirection>([.input]),
        Set<DeviceConfiguration.StreamDirection>([.output]),
        Set<DeviceConfiguration.StreamDirection>([.input, .output]),
    ])
    func swiftConfigurationIsExposedThroughHAL(streams: Set<DeviceConfiguration.StreamDirection>) throws {
        let driver = try Driver(configuration: configuration(streams: streams))
        let deviceID = try readProperty(
            driver, objectID: kAudioObjectPlugInObject,
            selector: kAudioPlugInPropertyDeviceList, initial: AudioObjectID(0)
        )
        let rate = try readProperty(
            driver, objectID: deviceID,
            selector: kAudioDevicePropertyNominalSampleRate, initial: Float64(0)
        )
        #expect(rate == 48000)
        let uid: Unmanaged<CFString>? = try readProperty(
            driver, objectID: deviceID,
            selector: kAudioDevicePropertyDeviceUID, initial: nil
        )
        #expect(try #require(uid).takeRetainedValue() as String == "studio.bonjour.aspl.test")

        for (direction, scope) in [
            (DeviceConfiguration.StreamDirection.input, kAudioObjectPropertyScopeInput),
            (DeviceConfiguration.StreamDirection.output, kAudioObjectPropertyScopeOutput),
        ] {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )
            let reference = driver.reference
            let interface = try #require(reference.pointee)
            let getSize = interface.pointee.GetPropertyDataSize
            var size: UInt32 = 0
            #expect(getSize(reference, deviceID, 0, &address, 0, nil, &size) == noErr)
            #expect(size == (streams.contains(direction) ? MemoryLayout<AudioObjectID>.size : 0))
            if streams.contains(direction) {
                let streamID = try readProperty(
                    driver, objectID: deviceID,
                    selector: kAudioDevicePropertyStreams, scope: scope, initial: AudioObjectID(0)
                )
                let format = try readProperty(
                    driver, objectID: streamID,
                    selector: kAudioStreamPropertyPhysicalFormat, initial: AudioStreamBasicDescription()
                )
                #expect(format.mSampleRate == 48000)
                #expect(format.mChannelsPerFrame == 1)
                #expect(format.mBitsPerChannel == 16)
            }
        }
    }

    @Test(arguments: [UInt32(0), UInt32.max])
    func invalidChannelCountsAreRejected(channelCount: UInt32) {
        #expect(throws: Driver.CreationError.invalidConfiguration) {
            try Driver(configuration: configuration(channelCount: channelCount))
        }
    }

    @Test func invalidConfigurationsAreRejected() {
        for value in [
            configuration(streams: []),
            configuration(sampleRate: 0),
            configuration(name: ""),
            configuration(name: "prefix\0suffix"),
            configuration(manufacturer: "prefix\0suffix"),
            configuration(uid: ""),
            configuration(uid: "prefix\0suffix"),
        ] {
            #expect(throws: Driver.CreationError.invalidConfiguration) {
                try Driver(configuration: value)
            }
        }
    }

    @Test func unicodeMetadataIsCopiedIntoTheDriver() throws {
        let driver = try Driver(configuration: configuration(
            name: "测试麦克风 🎙️", manufacturer: "音频设备", uid: "com.example.麦克风"
        ))
        let deviceID = try readProperty(
            driver, objectID: kAudioObjectPlugInObject,
            selector: kAudioPlugInPropertyDeviceList, initial: AudioObjectID(0)
        )
        for (selector, expected) in [
            (kAudioObjectPropertyName, "测试麦克风 🎙️"),
            (kAudioObjectPropertyManufacturer, "音频设备"),
            (kAudioDevicePropertyDeviceUID, "com.example.麦克风"),
        ] {
            let value: Unmanaged<CFString>? = try readProperty(
                driver, objectID: deviceID, selector: selector, initial: nil
            )
            #expect(try #require(value).takeRetainedValue() as String == expected)
        }
    }

    private func configuration(
        streams: Set<DeviceConfiguration.StreamDirection> = [.input],
        sampleRate: UInt32 = 48000,
        channelCount: UInt32 = 1,
        name: String = "ASPL Test Device",
        manufacturer: String = "Bonjour, LLC",
        uid: String = "studio.bonjour.aspl.test"
    ) -> DeviceConfiguration {
        DeviceConfiguration(
            name: name, manufacturer: manufacturer, uid: uid,
            sampleRate: sampleRate, channelCount: channelCount, streams: streams
        )
    }

    private func readProperty<Value>(
        _ driver: Driver,
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        initial: Value
    ) throws -> Value {
        var address = AudioObjectPropertyAddress(
            mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain
        )
        var value = initial
        var size: UInt32 = 0
        let reference = driver.reference
        let interface = try #require(reference.pointee)
        let getData = interface.pointee.GetPropertyData
        let status = withUnsafeMutablePointer(to: &value) { pointer in
            getData(
                reference, objectID, 0, &address, 0, nil,
                UInt32(MemoryLayout<Value>.size), &size, pointer
            )
        }
        try #require(status == noErr)
        try #require(size == MemoryLayout<Value>.size)
        return value
    }
}
