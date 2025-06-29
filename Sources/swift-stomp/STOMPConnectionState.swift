//
//  STOMPConnectionState.swift
//  swift-stomp
//
//  Created by Cole M on 5/3/23.
//
//  Copyright (c) 2025 NeedleTail Organization. 
//
//  This project is licensed under the MIT License.
//
//  See the LICENSE file for more information.
//
//  This file is part of the Swift STOMP SDK, which provides
//  STOMP protocol implementation for Swift applications.
//

import Foundation

public enum STOMPConnectionState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case disconnecting
    case error(STOMPError)
    
    public var isConnected: Bool {
        switch self {
        case .connected:
            return true
        default:
            return false
        }
    }
    
    public var isConnecting: Bool {
        switch self {
        case .connecting, .reconnecting:
            return true
        default:
            return false
        }
    }
    
    public var isDisconnected: Bool {
        switch self {
        case .disconnected, .error:
            return true
        default:
            return false
        }
    }
    
    public var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting"
        case .disconnecting:
            return "Disconnecting"
        case .error(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
}

public struct STOMPConnectionInfo: Sendable {
    public let sessionId: String?
    public let serverVersion: String?
    public let serverName: String?
    public let heartbeat: STOMPHeartbeat?
    public let connectedAt: Date
    
    public init(
        sessionId: String? = nil,
        serverVersion: String? = nil,
        serverName: String? = nil,
        heartbeat: STOMPHeartbeat? = nil,
        connectedAt: Date = Date()
    ) {
        self.sessionId = sessionId
        self.serverVersion = serverVersion
        self.serverName = serverName
        self.heartbeat = heartbeat
        self.connectedAt = connectedAt
    }
} 