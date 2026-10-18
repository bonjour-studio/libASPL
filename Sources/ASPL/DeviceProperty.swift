//
//  DeviceProperty.swift
//  ASPL
//
//  Created by Bonjour, LLC on 2026/10/18.
//

import CoreAudio

/// A custom CFPropertyList device property, marshalled by Core Audio between processes.
/// Callbacks run off the audio thread and may run concurrently with I/O. The consumer
/// owns synchronization and must keep the borrowed context alive until driver destruction.
public struct DeviceProperty {
    public typealias CopyValue = @convention(c) (UnsafeMutableRawPointer?) -> Unmanaged<CFPropertyList>?
    public typealias SetValue = @convention(c) (UnsafeMutableRawPointer?, CFPropertyList) -> Void

    public let selector: AudioObjectPropertySelector
    public let context: UnsafeMutableRawPointer?
    public let copyValue: CopyValue
    public let setValue: SetValue?

    /// The getter returns a retained value; the setter borrows its value. Omitting
    /// the setter makes the property read-only. Selectors must be unique per device.
    public init(selector: AudioObjectPropertySelector, context: UnsafeMutableRawPointer? = nil,
                copyValue: @escaping CopyValue, setValue: SetValue? = nil) {
        self.selector = selector
        self.context = context
        self.copyValue = copyValue
        self.setValue = setValue
    }
}
