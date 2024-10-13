//
//  STOMPOutboundHandler.swift
//  
//
//  Created by Cole M on 5/3/23.
//

import Foundation


public protocol TransportBridge: AnyObject, Sendable {
    func passData(_ string: String) async throws
}

public final class STOMPOutboundHandler: StompProtocol, @unchecked Sendable {
    
    public weak var delegate: TransportBridge?
    
    public func connect(_ string: String) async throws {
        try await delegate?.passData(string)
    }
    
    public func send(_ string: String) async throws {
        try await delegate?.passData(string)
    }
    
    public func subscribe(_ string: String) async throws {
        try await delegate?.passData(string)
    }
    
    public func unsubscribe(_ string: String) async throws {
        try await delegate?.passData(string)
    }
    
    public func begin(_ string: String) async throws {
        try await delegate?.passData(string)
    }
    
    public func commit(_ string: String) async throws {
        try await delegate?.passData(string)
    }
    
    public func abort(_ string: String) async throws {
        try await delegate?.passData(string)
    }
    
    public func acknowgledge(_ string: String) async throws {
        try await delegate?.passData(string)
    }
    
    public func negativelyAcknowgledge(_ string: String) async throws {
        try await delegate?.passData(string)
    }
    
    public func disconnected(_ string: String) async throws {
        try await delegate?.passData(string)
    }
    
}
