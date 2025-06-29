//
//  STOMPHeaders.swift
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

public enum STOMPHeaders: String, CustomStringConvertible, Sendable {
    
    case contentLength = "content-length"
    case contentType = "content-type"
    case acceptVersion = "accept-version"
    case host
    case login
    case passcode
    case heartbeat
    case version
    case session
    case server
    case destination
    case id
    case ack
    case transaction
    case receipt
    case messageId = "message-id"
    case subscription
    case receiptId = "receipt-id"
    case message
    case customHeaders = "custom-headers"
    
    public var description: String {
        switch self {
        case .contentLength:
            return "content-length"
        case .contentType:
            return "content-type"
        case .acceptVersion:
            return "accept-version"
        case .host:
            return "host"
        case .login:
            return "login"
        case .passcode:
            return "passcode"
        case .heartbeat:
            return "heart-beat"
        case .version:
            return "version"
        case .session:
            return "session"
        case .server:
            return "server"
        case .destination:
            return "destination"
        case .id:
            return "id"
        case .ack:
            return "ack"
        case .transaction:
            return "transaction"
        case .receipt:
            return "receipt"
        case .messageId:
            return "message-id"
            // Within the same connection, different subscriptions MUST use different subscription identifiers.
        case .subscription:
            return "subscription"
        case .receiptId:
            return "receipt-id"
        case .message:
            return "message"
        case .customHeaders:
            return "customHeaders"
        }
    }
}
