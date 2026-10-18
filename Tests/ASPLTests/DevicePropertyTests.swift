//
//  DevicePropertyTests.swift
//  ASPLTests
//
//  Created by Bonjour, LLC on 2026/10/18.
//

import ASPL
import CoreAudio
import Foundation
import Testing

private final class PropertyState {
    var value = Data([1, 2, 3])
}

struct DevicePropertyTests {
    @Test func customPropertyRoundTripsThroughHAL() throws {
        let state = PropertyState()
        let selector: AudioObjectPropertySelector = 0x74737470
        let driver = try Driver(configuration: configuration, properties: [
            DeviceProperty(selector: selector, context: Unmanaged.passUnretained(state).toOpaque(), copyValue: { context in
                let state = Unmanaged<PropertyState>.fromOpaque(context!).takeUnretainedValue()
                return .passRetained(state.value as CFData)
            }, setValue: { context, value in
                let state = Unmanaged<PropertyState>.fromOpaque(context!).takeUnretainedValue()
                state.value = value as! Data
            }),
        ])
        let ref = driver.reference
        let api = ref.pointee!.pointee
        let device: AudioObjectID = try read(ref, kAudioObjectPlugInObject, kAudioPlugInPropertyDeviceList, initial: 0)
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var settable = DarwinBoolean(false)
        #expect(api.HasProperty(ref, device, 0, &address).boolValue)
        #expect(api.IsPropertySettable(ref, device, 0, &address, &settable) == noErr)
        #expect(settable.boolValue)
        let metadata: AudioServerPlugInCustomPropertyInfo = try read(ref, device, kAudioObjectPropertyCustomPropertyInfoList, initial: .init())
        #expect(metadata.mSelector == selector)
        #expect(metadata.mPropertyDataType == kAudioServerPlugInCustomPropertyDataTypeCFPropertyList)
        var value: CFPropertyList = Data([9, 8, 7, 6]) as CFData
        withUnsafePointer(to: &value) {
            #expect(api.SetPropertyData(ref, device, 0, &address, 0, nil, UInt32(MemoryLayout<CFPropertyList>.size), $0) == noErr)
        }
        let copied: Unmanaged<CFPropertyList>? = try read(ref, device, selector, initial: nil)
        #expect(try #require(copied).takeRetainedValue() as! Data == Data([9, 8, 7, 6]))
        #expect(state.value == Data([9, 8, 7, 6]))
        withExtendedLifetime(state) {}
    }

    @Test func readOnlyAndDuplicateProperties() throws {
        let property = DeviceProperty(selector: 0x74737470, copyValue: { _ in .passRetained(Data() as CFData) })
        #expect(throws: Driver.CreationError.invalidConfiguration) {
            try Driver(configuration: configuration, properties: [property, property])
        }
        let driver = try Driver(configuration: configuration, properties: [property])
        let ref = driver.reference
        let device: AudioObjectID = try read(ref, kAudioObjectPlugInObject, kAudioPlugInPropertyDeviceList, initial: 0)
        var address = AudioObjectPropertyAddress(mSelector: property.selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var settable = DarwinBoolean(true)
        #expect(ref.pointee!.pointee.IsPropertySettable(ref, device, 0, &address, &settable) == noErr)
        #expect(!settable.boolValue)
    }

    private var configuration: DeviceConfiguration {
        DeviceConfiguration(name: "Property Test", manufacturer: "Test", uid: "com.example.properties",
                            sampleRate: 48000, channelCount: 1, streams: [.input])
    }

    private func read<T>(_ ref: AudioServerPlugInDriverRef, _ object: AudioObjectID,
                         _ selector: AudioObjectPropertySelector, initial: T) throws -> T {
        var value = initial
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        let status = withUnsafeMutablePointer(to: &value) {
            ref.pointee!.pointee.GetPropertyData(ref, object, 0, &address, 0, nil, UInt32(MemoryLayout<T>.size), &size, $0)
        }
        try #require(status == noErr)
        return value
    }
}
