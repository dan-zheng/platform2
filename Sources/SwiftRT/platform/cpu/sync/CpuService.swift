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

//==============================================================================
/// CpuService
/// The collection of compute resources available to the application
/// on the machine where the process is being run.
public class CpuService: PlatformService {
    // properties
    public let devices: [CpuDevice<CpuQueue>]
    public let logInfo: LogInfo
    public let name: String
    public var queueStack: [QueueId]

    //--------------------------------------------------------------------------
    @inlinable
    public init() {
        self.name = "CpuService"
        self.logInfo = LogInfo(logWriter: Platform.log,
                               logLevel: .error,
                               namePath: self.name,
                               nestingLevel: 0)
        self.devices = [
            CpuDevice<CpuQueue>(parent: logInfo, memoryType: .unified, id: 0)
        ]
        
        // select device 0 queue 0 by default
        self.queueStack = []
        self.queueStack = [ensureValidId(0, 0)]
    }
}

//==============================================================================
/// CpuBuffer
/// Used to manage a host memory buffer
public final class CpuBuffer<Element>: ElementBuffer {
    public let buffer: UnsafeMutableBufferPointer<Element>
    public let id: Int
    public let isReadOnly: Bool
    public let isReference: Bool
    public let name: String
    
    //--------------------------------------------------------------------------
    // init(count:name:
    @inlinable
    public init(count: Int, name: String) {
        self.buffer = UnsafeMutableBufferPointer.allocate(capacity: count)
        self.id = Platform.nextBufferId
        self.isReadOnly = false
        self.isReference = false
        self.name = name
        
        #if DEBUG
        diagnostic("\(createString) \(name)(\(id)) " +
            "\(Element.self)[\(count)]", categories: .dataAlloc)
        #endif
    }
    
    //--------------------------------------------------------------------------
    // init(elements:name:
    @inlinable
    public convenience init<C>(elements: C, name: String)
        where C: Collection, C.Element == Element
    {
        self.init(count: elements.count, name: name)
        _ = buffer.initialize(from: elements)
    }
    
    //--------------------------------------------------------------------------
    // init(buffer:name:
    @inlinable
    public init(referenceTo buffer: UnsafeBufferPointer<Element>, name: String) {
        self.buffer = UnsafeMutableBufferPointer(mutating: buffer)
        self.id = Platform.nextBufferId
        self.isReadOnly = true
        self.isReference = true
        self.name = name
        
        #if DEBUG
        diagnostic("\(createString) Reference \(name)(\(id)) " +
            "\(Element.self)[\(buffer.count)]", categories: .dataAlloc)
        #endif
    }
    
    //--------------------------------------------------------------------------
    // init(buffer:name:
    @inlinable
    public init(referenceTo buffer: UnsafeMutableBufferPointer<Element>,
                name: String)
    {
        self.buffer = buffer
        self.id = Platform.nextBufferId
        self.isReadOnly = false
        self.isReference = true
        self.name = name
        
        #if DEBUG
        diagnostic("\(createString) Reference \(name)(\(id)) " +
            "\(Element.self)[\(buffer.count)]", categories: .dataAlloc)
        #endif
    }
    
    //--------------------------------------------------------------------------
    // streaming
    @inlinable
    public init<Shape, Stream>(block shape: Shape, bufferedBlocks: Int,
                               stream: Stream)
        where Shape : ShapeProtocol, Stream : BufferStream
    {
        fatalError()
    }
    
    //--------------------------------------------------------------------------
    // single element
    @inlinable
    public init(for element: Element)
    {
        fatalError()
    }
    
    //--------------------------------------------------------------------------
    // deinit
    @inlinable
    deinit {
        if !isReference {
            buffer.deallocate()
            #if DEBUG
            diagnostic("\(releaseString) \(name)(\(id)) ",
                categories: .dataAlloc)
            #endif
        }
    }
    
    //--------------------------------------------------------------------------
    // duplicate
    @inlinable
    public func duplicate() -> CpuBuffer {
        let roBuffer = UnsafeRawBufferPointer(buffer)
        let newBuffer = CpuBuffer(count: roBuffer.count, name: name)
        _ = newBuffer.buffer.initialize(from: buffer)
        return newBuffer
    }
    
    //--------------------------------------------------------------------------
    // read
    @inlinable
    public func read(at offset: Int, count: Int, using queue: DeviceQueue)
        -> UnsafeBufferPointer<Element>
    {
        let start = buffer.baseAddress!.advanced(by: offset)
        return UnsafeBufferPointer(start: start, count: count)
    }
    
    //--------------------------------------------------------------------------
    // readWrite
    @inlinable
    public func readWrite(at offset: Int, count: Int, willOverwrite: Bool,
                          using queue: DeviceQueue)
        -> UnsafeMutableBufferPointer<Element>
    {
        let start = buffer.baseAddress!.advanced(by: offset)
        return UnsafeMutableBufferPointer(start: start, count: count)
    }
}

