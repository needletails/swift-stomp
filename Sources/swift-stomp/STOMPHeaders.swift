//
//  STOMPHeaders.swift
//  
//
//  Created by Cole M on 5/3/23.
//

import Foundation

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

public enum EncodingType: Sendable {
    case utf8, utf16
    
    var description: String {
        switch self {
        case .utf8:
            return "utf-8"
        case .utf16:
            return "utf-16"
        }
    }
}

public struct Charset: Sendable {
    
    var charset: String = ""
    
    init(encoding: EncodingType) {
        self.charset = ";charset=\(encoding.description)"
    }
}


public enum MIMEType: String, Sendable {
    case text, application
}

public enum MIMESubType: String, Sendable {
    case html, json, xml, plain
}

public struct MIME: Sendable {
    
    var mime: String = ""
    
    init(type: MIMEType, subType: MIMESubType) {
        self.mime = "\(type)/\(subType)"
    }
}
