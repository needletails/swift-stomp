//
//  STOMPSubscription.swift
//  
//
//  Created by Cole M on 5/3/23.
//

import Foundation

public struct STOMPSubscription: Sendable {
    public let id: String
    public let destination: String
    public let ackMode: ACKMode
    public let selector: String?
    public let customHeaders: [String: String]
    public let createdAt: Date
    
    // Message tracking for client acknowledgment modes
    private var pendingMessages: [String: STOMPFrame] = [:]
    private var acknowledgedMessages: Set<String> = []
    
    public init(
        id: String,
        destination: String,
        ackMode: ACKMode = .auto,
        selector: String? = nil,
        customHeaders: [String: String] = [:]
    ) {
        self.id = id
        self.destination = destination
        self.ackMode = ackMode
        self.selector = selector
        self.customHeaders = customHeaders
        self.createdAt = Date()
    }
    
    // MARK: - Message Management
    
    mutating func addMessage(_ message: STOMPFrame) {
        guard let messageId = message.headers[STOMPHeaders.messageId.description] else { return }
        
        switch ackMode {
        case .auto:
            // Auto acknowledgment - no tracking needed
            break
        case .client, .clientIndividual:
            pendingMessages[messageId] = message
        }
    }
    
    mutating func acknowledgeMessage(_ messageId: String) {
        pendingMessages.removeValue(forKey: messageId)
        acknowledgedMessages.insert(messageId)
    }
    
    mutating func negativeAcknowledgeMessage(_ messageId: String) {
        pendingMessages.removeValue(forKey: messageId)
    }
    
    func getPendingMessages() -> [STOMPFrame] {
        return Array(pendingMessages.values)
    }
    
    func hasPendingMessages() -> Bool {
        return !pendingMessages.isEmpty
    }
    
    func isMessagePending(_ messageId: String) -> Bool {
        return pendingMessages[messageId] != nil
    }
    
    func isMessageAcknowledged(_ messageId: String) -> Bool {
        return acknowledgedMessages.contains(messageId)
    }
    
    // MARK: - Cumulative Acknowledgment (for client mode)
    
    func getMessagesToAcknowledgeCumulatively(upTo messageId: String) -> [String] {
        guard ackMode == .client else { return [messageId] }
        
        var messageIds: [String] = []
        for (id, _) in pendingMessages {
            if id <= messageId {
                messageIds.append(id)
            }
        }
        return messageIds.sorted()
    }
}

public struct STOMPMessage: Sendable {
    public let id: String
    public let destination: String
    public let subscription: String
    public let body: BodyType?
    public let headers: [String: String]
    public let receivedAt: Date
    
    public init(from frame: STOMPFrame) {
        self.id = frame.headers[STOMPHeaders.messageId.description] ?? ""
        self.destination = frame.headers[STOMPHeaders.destination.description] ?? ""
        self.subscription = frame.headers[STOMPHeaders.subscription.description] ?? ""
        self.body = frame.body
        self.headers = frame.headers
        self.receivedAt = Date()
    }
    
    public var bodyString: String? {
        switch body {
        case .string(let string):
            return string
        case .data(let data):
            return String(data: data, encoding: .utf8)
        default:
            return nil
        }
    }
    
    public var bodyData: Data? {
        switch body {
        case .data(let data):
            return data
        case .string(let string):
            return string.data(using: .utf8)
        default:
            return nil
        }
    }
} 