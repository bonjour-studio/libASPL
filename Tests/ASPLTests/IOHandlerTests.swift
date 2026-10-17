//
//  IOHandlerTests.swift
//  ASPLTests
//
//  Created by Bonjour, LLC on 2026/10/18.
//

import ASPL
import CoreAudio
import Testing

private struct CallbackState {
    var resetCount = 0
    var readTime = 0.0
    var writeTime = 0.0
    var sample: Float = 0
}

struct IOHandlerTests {
    @Test func float32CallbacksAndSessionLifecycle() throws {
        let context = UnsafeMutablePointer<CallbackState>.allocate(capacity: 1)
        context.initialize(to: CallbackState())
        defer { context.deinitialize(count: 1); context.deallocate() }
        let driver = try Driver(configuration: DeviceConfiguration(
            name: "Callback Test", manufacturer: "Test", uid: "com.example.callbacks",
            sampleRate: 48000, channelCount: 1, streams: [.input, .output], sampleFormat: .float32
        ), ioHandler: IOHandler(context: context, read: { context, time, bytes, count in
            let state = context!.assumingMemoryBound(to: CallbackState.self)
            state.pointee.readTime = time
            let samples = bytes!.assumingMemoryBound(to: Float.self)
            for i in 0..<(Int(count) / 4) { samples[i] = state.pointee.sample }
        }, write: { context, time, bytes, _ in
            let state = context!.assumingMemoryBound(to: CallbackState.self)
            state.pointee.writeTime = time
            state.pointee.sample = bytes!.load(as: Float.self)
        }, reset: { context in
            let state = context!.assumingMemoryBound(to: CallbackState.self)
            state.pointee.resetCount += 1
            state.pointee.sample = 0
        }))
        defer { withExtendedLifetime(driver) {} }
        let ref = driver.reference
        let api = try #require(ref.pointee).pointee
        let host = UnsafeMutablePointer<AudioServerPlugInHostInterface>.allocate(capacity: 1)
        host.initialize(to: AudioServerPlugInHostInterface(
            PropertiesChanged: { _, _, _, _ in noErr },
            CopyFromStorage: { _, _, value in value.pointee = nil; return noErr },
            WriteToStorage: { _, _, _ in noErr }, DeleteFromStorage: { _, _ in noErr },
            RequestDeviceConfigurationChange: { _, _, _, _ in kAudioHardwareUnsupportedOperationError }
        ))
        defer { host.deinitialize(count: 1); host.deallocate() }
        #expect(api.Initialize(ref, host) == noErr)
        let device: AudioObjectID = try property(ref, kAudioObjectPlugInObject, kAudioPlugInPropertyDeviceList, initial: 0)
        let input: AudioObjectID = try property(ref, device, kAudioDevicePropertyStreams, scope: kAudioObjectPropertyScopeInput, initial: 0)
        let output: AudioObjectID = try property(ref, device, kAudioDevicePropertyStreams, scope: kAudioObjectPropertyScopeOutput, initial: 0)
        let format = try property(ref, input, kAudioStreamPropertyPhysicalFormat, initial: AudioStreamBasicDescription())
        #expect(format.mFormatFlags & kAudioFormatFlagIsFloat != 0 && format.mBitsPerChannel == 32 && format.mBytesPerFrame == 4)
        for id: UInt32 in [1, 2] {
            var client = AudioServerPlugInClientInfo(mClientID: id, mProcessID: getpid(), mIsNativeEndian: true, mBundleID: nil)
            #expect(api.AddDeviceClient(ref, device, &client) == noErr)
            #expect(api.StartIO(ref, device, id) == noErr)
        }
        #expect(context.pointee.resetCount == 1)
        var cycle = AudioServerPlugInIOCycleInfo()
        cycle.mOutputTime.mSampleTime = 4096
        cycle.mInputTime.mSampleTime = 4096
        var samples: [Float] = [0.375, 0.375, 0.375, 0.375]
        samples.withUnsafeMutableBytes {
            #expect(api.DoIOOperation(ref, device, output, 1, AudioServerPlugInIOOperation.writeMix.rawValue, 4, &cycle, $0.baseAddress, nil) == noErr)
        }
        for id: UInt32 in [1, 2] {
            samples = [Float](repeating: -1, count: 4)
            samples.withUnsafeMutableBytes {
                #expect(api.DoIOOperation(ref, device, input, id, AudioServerPlugInIOOperation.readInput.rawValue, 4, &cycle, $0.baseAddress, nil) == noErr)
            }
            #expect(samples == [Float](repeating: 0.375, count: 4))
        }
        #expect(context.pointee.writeTime == 4096 && context.pointee.readTime == 4096)
        #expect(api.StopIO(ref, device, 1) == noErr)
        #expect(context.pointee.resetCount == 1)
        #expect(api.StopIO(ref, device, 2) == noErr)
        #expect(context.pointee.resetCount == 2)
        #expect(context.pointee.sample == 0)
    }

    private func property<T>(_ ref: AudioServerPlugInDriverRef, _ object: AudioObjectID,
        _ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        initial: T) throws -> T {
        var value = initial
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        let result = withUnsafeMutablePointer(to: &value) {
            ref.pointee!.pointee.GetPropertyData(ref, object, 0, &address, 0, nil, UInt32(MemoryLayout<T>.size), &size, $0)
        }
        try #require(result == noErr)
        return value
    }
}
