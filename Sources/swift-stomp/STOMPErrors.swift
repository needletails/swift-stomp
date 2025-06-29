//
//  STOMPErrors.swift
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

public enum STOMPError: Error, LocalizedError, Sendable, Equatable {
    case invalidCommand(String)
    case invalidFirstLine(String)
    case invalidACK(String)
    case invalidBody(String)
    case connectionFailed(String)
    case connectionTimeout
    case authenticationFailed(String)
    case subscriptionFailed(String)
    case messageDeliveryFailed(String)
    case transactionFailed(String)
    case heartbeatTimeout
    case protocolError(String)
    case serverError(String)
    case transportError(String)
    case encodingError(String)
    case decodingError(String)
    case invalidFrame(String)
    case missingRequiredHeader(String)
    case invalidHeaderValue(String, String)
    case messageTooLarge(Int, Int)
    case unsupportedVersion(String)
    case destinationNotFound(String)
    case accessDenied(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCommand(let command):
            return "Invalid STOMP command: \(command)"
        case .invalidFirstLine(let line):
            return "Invalid first line in frame: \(line)"
        case .invalidACK(let ack):
            return "Invalid ACK mode: \(ack)"
        case .invalidBody(let body):
            return "Invalid message body: \(body)"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .connectionTimeout:
            return "Connection timeout"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .subscriptionFailed(let reason):
            return "Subscription failed: \(reason)"
        case .messageDeliveryFailed(let reason):
            return "Message delivery failed: \(reason)"
        case .transactionFailed(let reason):
            return "Transaction failed: \(reason)"
        case .heartbeatTimeout:
            return "Heartbeat timeout"
        case .protocolError(let message):
            return "Protocol error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .transportError(let message):
            return "Transport error: \(message)"
        case .encodingError(let message):
            return "Encoding error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .invalidFrame(let frame):
            return "Invalid frame: \(frame)"
        case .missingRequiredHeader(let header):
            return "Missing required header: \(header)"
        case .invalidHeaderValue(let header, let value):
            return "Invalid value '\(value)' for header '\(header)'"
        case .messageTooLarge(let actual, let max):
            return "Message too large: \(actual) bytes (max: \(max))"
        case .unsupportedVersion(let version):
            return "Unsupported STOMP version: \(version)"
        case .destinationNotFound(let destination):
            return "Destination not found: \(destination)"
        case .accessDenied(let reason):
            return "Access denied: \(reason)"
        }
    }
} 