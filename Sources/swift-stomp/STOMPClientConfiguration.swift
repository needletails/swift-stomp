//
//  STOMPClientConfiguration.swift
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

public struct STOMPClientConfiguration: Sendable {
    // Connection settings
    public let host: String
    public let port: Int
    public let useSSL: Bool
    public let connectionTimeout: TimeInterval
    public let readTimeout: TimeInterval
    public let writeTimeout: TimeInterval
    
    // Authentication
    public let login: String?
    public let passcode: String?
    
    // STOMP protocol settings
    public let acceptVersion: String
    public let virtualHost: String
    
    // Heartbeat settings
    public let heartbeatSendInterval: TimeInterval
    public let heartbeatReceiveInterval: TimeInterval
    public let heartbeatTimeout: TimeInterval
    
    // Message settings
    public let maxMessageSize: Int
    public let defaultContentType: String
    
    // Retry settings
    public let maxReconnectAttempts: Int
    public let reconnectDelay: TimeInterval
    public let maxReconnectDelay: TimeInterval
    public let reconnectBackoffMultiplier: Double
    
    // Logging
    public let enableLogging: Bool
    public let logLevel: LogLevel
    
    // Custom headers
    public let customHeaders: [String: String]
    
    public enum LogLevel: String, Sendable {
        case debug, info, warning, error
    }
    
    public init(
        host: String,
        port: Int = 61613,
        useSSL: Bool = false,
        connectionTimeout: TimeInterval = 30.0,
        readTimeout: TimeInterval = 60.0,
        writeTimeout: TimeInterval = 30.0,
        login: String? = nil,
        passcode: String? = nil,
        acceptVersion: String = "1.2",
        virtualHost: String? = nil,
        heartbeatSendInterval: TimeInterval = 0,
        heartbeatReceiveInterval: TimeInterval = 0,
        heartbeatTimeout: TimeInterval = 30.0,
        maxMessageSize: Int = 1024 * 1024, // 1MB
        defaultContentType: String = "text/plain",
        maxReconnectAttempts: Int = 5,
        reconnectDelay: TimeInterval = 1.0,
        maxReconnectDelay: TimeInterval = 60.0,
        reconnectBackoffMultiplier: Double = 2.0,
        enableLogging: Bool = false,
        logLevel: LogLevel = .info,
        customHeaders: [String: String] = [:]
    ) {
        self.host = host
        self.port = port
        self.useSSL = useSSL
        self.connectionTimeout = connectionTimeout
        self.readTimeout = readTimeout
        self.writeTimeout = writeTimeout
        self.login = login
        self.passcode = passcode
        self.acceptVersion = acceptVersion
        self.virtualHost = virtualHost ?? host
        self.heartbeatSendInterval = heartbeatSendInterval
        self.heartbeatReceiveInterval = heartbeatReceiveInterval
        self.heartbeatTimeout = heartbeatTimeout
        self.maxMessageSize = maxMessageSize
        self.defaultContentType = defaultContentType
        self.maxReconnectAttempts = maxReconnectAttempts
        self.reconnectDelay = reconnectDelay
        self.maxReconnectDelay = maxReconnectDelay
        self.reconnectBackoffMultiplier = reconnectBackoffMultiplier
        self.enableLogging = enableLogging
        self.logLevel = logLevel
        self.customHeaders = customHeaders
    }
    
    public var heartbeat: STOMPHeartbeat {
        STOMPHeartbeat(
            send: Int(heartbeatSendInterval * 1000),
            receive: Int(heartbeatReceiveInterval * 1000)
        )
    }
} 