//
//  IOHandler.swift
//  ASPL
//
//  Created by Bonjour, LLC on 2026/10/18.
//

/// C function pointers let real-time audio stay in C/C++ without Swift closure allocation.
/// Keep `context` alive until the driver is destroyed. Configure handlers before publishing
/// the HAL reference. Read/write receive native PCM bytes and a sample-frame timestamp;
/// libASPL serializes these calls. They must not block, allocate, or throw.
public struct IOHandler {
    public typealias Read = @convention(c) (UnsafeMutableRawPointer?, Double, UnsafeMutableRawPointer?, UInt32) -> Void
    public typealias Write = @convention(c) (UnsafeMutableRawPointer?, Double, UnsafeRawPointer?, UInt32) -> Void
    public typealias Reset = @convention(c) (UnsafeMutableRawPointer?) -> Void

    public let context: UnsafeMutableRawPointer?
    public let read: Read?
    public let write: Write?
    public let reset: Reset?

    /// Missing reads produce silence; missing writes are ignored. Reset runs before
    /// the first client starts I/O and after the last client stops, off the audio thread.
    public init(context: UnsafeMutableRawPointer? = nil, read: Read? = nil, write: Write? = nil, reset: Reset? = nil) {
        self.context = context
        self.read = read
        self.write = write
        self.reset = reset
    }
}
