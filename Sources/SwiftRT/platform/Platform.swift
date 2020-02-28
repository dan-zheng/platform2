//******************************************************************************
// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import Foundation

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#else
import Glibc
#endif

//==============================================================================
/// Platform
/// Manages the scope for the current devices, log, and error handlers
public final class Platform {
    /// the time that the platform was first accessed
    @usableFromInline static var startTime = Date()
    /// the log output object
    @usableFromInline static var logWriter: Log = Log()
    /// the current compute platform for the thread
    //    @usableFromInline var platform: PlatformService
    /// a platform instance unique id for queue events
    @usableFromInline static var queueEventCounter: Int = 0
    /// counter for unique buffer ids
    @usableFromInline static var bufferIdCounter: Int = 0

    // maybe thread local
    // TODO(TF-1181): Fix crash regarding existential. Use concrete type for now.
    // public static var service: PlatformAPI = CpuService()
    public static var service = CpuService()
    
    //--------------------------------------------------------------------------
    /// the Platform log writing object
    @inlinable public static var log: Log {
        get { logWriter }
        set { logWriter = newValue }
    }
    /// a counter used to uniquely identify queue events for diagnostics
    @inlinable static var nextQueueEventId: Int {
        queueEventCounter += 1
        return queueEventCounter
    }
    /// nextBufferRef
    @inlinable public static var nextBufferRef: BufferRef {
        Self.bufferIdCounter += 1
        return BufferRef(Self.bufferIdCounter)
    }

    //--------------------------------------------------------------------------
    /// returns the thread local instance of the queues stack
    @usableFromInline
    static var threadLocal: Platform {
        // try to get an existing state
        if let state = pthread_getspecific(key) {
            return Unmanaged.fromOpaque(state).takeUnretainedValue()
        } else {
            // create and return new state
            let state = Platform()
            pthread_setspecific(key, Unmanaged.passRetained(state).toOpaque())
            return state
        }
    }
    
    //--------------------------------------------------------------------------
    /// thread data key
    @usableFromInline
    static let key: pthread_key_t = {
        var key = pthread_key_t()
        pthread_key_create(&key) {
            #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
            let _: AnyObject = Unmanaged.fromOpaque($0).takeRetainedValue()
            #else
            let _: AnyObject = Unmanaged.fromOpaque($0!).takeRetainedValue()
            #endif
        }
        return key
    }()
}

//==============================================================================
/// ServiceDevice
/// a compute device represents a physical service device installed
/// on the platform
public protocol ServiceDevice: Logger {
    associatedtype Queue: DeviceQueue

    /// the id of the device for example dev:0, dev:1, ...
    var id: Int { get }
    /// name used logging
    var name: String { get }
    /// a collection of device queues for scheduling work
    var queues: [Queue] { get }
    /// specifies the type of device memory for data transfer
    var memoryType: MemoryType { get }

    //-------------------------------------
    /// `allocate(bytes:heapIndex:`
    /// creates an array on this device
    /// - Parameter byteCount: the number of bytes to allocate on the device
    /// - Parameter heapIndex: the index of the heap to use
    /// - Returns: a device memory object. It is the callers responsibility
    /// to call deallocate when references drop to zero.
    func allocate(byteCount: Int, heapIndex: Int) -> DeviceMemory
}

//==============================================================================
/// DeviceMemory
public struct DeviceMemory {
    /// base address and size of buffer
    public let buffer: UnsafeMutableRawBufferPointer
    /// function to free the memory
    public let deallocate: () -> Void
    /// specifies the device memory type for data transfer
    public let memoryType: MemoryType
    /// version
    public var version: Int
    
    @inlinable
    public init(buffer: UnsafeMutableRawBufferPointer,
                memoryType: MemoryType,
                _ deallocate: @escaping () -> Void)
    {
        self.buffer = buffer
        self.memoryType = memoryType
        self.version = -1
        self.deallocate = deallocate
    }
}

//==============================================================================
/// DeviceQueue
/// A device queue is an asynchronous sequential list of commands to be
/// executed on the associated device.
public protocol DeviceQueue: Logger, DeviceFunctions {
    /// the thread that created this queue. Used to detect accidental access
    var creatorThread: Thread { get }
    /// options to use when creating queue events
    var defaultQueueEventOptions: QueueEventOptions { get }
    /// the device id that this queue is associated with
    var deviceId: Int { get }
    /// the id of the device for example queue:0, queue:1, ...
    var id: Int { get }
    /// name used logging
    var deviceName: String { get }
    /// name used logging
    var name: String { get }

    //--------------------------------------------------------------------------
    // synchronization functions
    /// creates a QueueEvent
    func createEvent(options: QueueEventOptions) -> QueueEvent
    /// queues a queue event op. When executed the event is signaled
    @discardableResult
    func record(event: QueueEvent) -> QueueEvent
    /// records an op on the queue that will perform a queue blocking wait
    /// when it is processed
    func wait(for event: QueueEvent)
    /// blocks the calling thread until the queue queue has completed all work
    func waitUntilQueueIsComplete()
    
    //--------------------------------------------------------------------------
    /// asynchronously copies the contents of a device memeory buffer to another
    func copyAsync(from deviceMemory: DeviceMemory,
                   to otherDeviceMemory: DeviceMemory)
}

//==============================================================================
/// QueueEvent
/// A queue event is a barrier synchronization object that is
/// - created by a `DeviceQueue`
/// - recorded on a queue to create a barrier
/// - waited on by one or more threads for group synchronization
public protocol QueueEvent {
    /// the id of the event for diagnostics
    var id: Int { get }
    /// is `true` if the even has occurred, used for polling
    var occurred: Bool { get }
    /// the last time the event was recorded
    var recordedTime: Date? { get set }

    /// measure elapsed time since another event
    func elapsedTime(since other: QueueEvent) -> TimeInterval?
    /// will block the caller until the timeout has elapsed if one
    /// was specified during init, otherwise it will block forever
    func wait() throws
}

//==============================================================================
public extension QueueEvent {
    /// elapsedTime
    /// computes the timeinterval between two queue event recorded times
    /// - Parameter other: the other event used to compute the interval
    /// - Returns: the elapsed interval. Will return `nil` if this event or
    ///   the other have not been recorded.
    @inlinable
    func elapsedTime(since other: QueueEvent) -> TimeInterval? {
        guard let time = recordedTime,
            let other = other.recordedTime else { return nil }
        return time.timeIntervalSince(other)
    }
}

//==============================================================================
/// QueueEventOptions
public struct QueueEventOptions: OptionSet {
    public let rawValue: Int
    public static let timing       = QueueEventOptions(rawValue: 1 << 0)
    public static let interprocess = QueueEventOptions(rawValue: 1 << 1)
    
    @inlinable
    public init() { self.rawValue = 0 }
    
    @inlinable
    public init(rawValue: Int) { self.rawValue = rawValue }
}

public enum QueueEventError: Error {
    case timedOut
}

//==============================================================================
/// MemoryType
public enum MemoryType {
    case unified, discreet
}

//==============================================================================
/// QueueId
/// a unique service device queue identifier that is used to index
/// through the service device tree for directing workflow
public struct QueueId {
    public let device: Int
    public let queue: Int
    
    @inlinable
    public init(_ device: Int, _ queue: Int) {
        self.device = device
        self.queue = queue
    }
}

//==============================================================================
// assert messages
@usableFromInline
let _messageQueueThreadViolation =
"a queue can only be accessed by the thread that created it"

