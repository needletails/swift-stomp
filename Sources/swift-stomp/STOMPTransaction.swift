//
//  STOMPTransaction.swift
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

public enum STOMPTransactionState: Sendable {
    case active
    case committed
    case aborted
    case timedOut
}

public struct STOMPTransaction: Sendable {
    public let id: String
    public private(set) var state: STOMPTransactionState
    public let createdAt: Date
    public let timeoutInterval: TimeInterval
    
    // Track messages and acknowledgments in this transaction
    private var pendingMessages: [String] = []
    private var pendingAcknowledgmentIds: [String] = []
    
    public init(id: String, timeout: TimeInterval = 30.0) {
        self.id = id
        self.state = .active
        self.createdAt = Date()
        self.timeoutInterval = timeout
    }
    
    public var isActive: Bool {
        return state == .active
    }
    
    public var isExpired: Bool {
        return Date().timeIntervalSince(createdAt) > timeoutInterval
    }
    
    mutating func addMessage(_ messageId: String) {
        guard isActive else { return }
        pendingMessages.append(messageId)
    }
    
    mutating func addAcknowledgment(_ messageId: String) {
        guard isActive else { return }
        pendingAcknowledgmentIds.append(messageId)
    }
    
    mutating func commit() {
        guard isActive else { return }
        state = .committed
    }
    
    mutating func abort() {
        guard isActive else { return }
        state = .aborted
    }
    
    mutating func markAsTimedOut() {
        guard isActive else { return }
        state = .timedOut
    }
    
    func getPendingMessages() -> [String] {
        return pendingMessages
    }
    
    func getPendingAcknowledgmentIds() -> [String] {
        return pendingAcknowledgmentIds
    }
    
    func hasPendingOperations() -> Bool {
        return !pendingMessages.isEmpty || !pendingAcknowledgmentIds.isEmpty
    }
}

public actor STOMPTransactionManager {
    private var transactions: [String: STOMPTransaction] = [:]
    
    public init() {}
    
    public func beginTransaction(id: String, timeout: TimeInterval = 30.0) async -> STOMPTransaction {
        let transaction = STOMPTransaction(id: id, timeout: timeout)
        transactions[id] = transaction
        return transaction
    }
    
    public func getTransaction(id: String) async -> STOMPTransaction? {
        return transactions[id]
    }
    
    public func commitTransaction(id: String) async -> Bool {
        guard var transaction = transactions[id], transaction.isActive else {
            return false
        }
        
        transaction.commit()
        transactions[id] = transaction
        return true
    }
    
    public func abortTransaction(id: String) async -> Bool {
        guard var transaction = transactions[id], transaction.isActive else {
            return false
        }
        
        transaction.abort()
        transactions[id] = transaction
        return true
    }
    
    public func addMessageToTransaction(transactionId: String, messageId: String) async -> Bool {
        guard var transaction = transactions[transactionId], transaction.isActive else {
            return false
        }
        
        transaction.addMessage(messageId)
        transactions[transactionId] = transaction
        return true
    }
    
    public func addAcknowledgmentToTransaction(transactionId: String, messageId: String) async -> Bool {
        guard var transaction = transactions[transactionId], transaction.isActive else {
            return false
        }
        
        transaction.addAcknowledgment(messageId)
        transactions[transactionId] = transaction
        return true
    }
    
    public func cleanupExpiredTransactions() async {
        let expiredIds = transactions.compactMap { (id, transaction) in
            transaction.isExpired ? id : nil
        }
        
        for id in expiredIds {
            if var transaction = transactions[id] {
                transaction.markAsTimedOut()
                transactions[id] = transaction
            }
        }
    }
    
    public func removeTransaction(id: String) async {
        transactions.removeValue(forKey: id)
    }
    
    public func getAllTransactions() async -> [STOMPTransaction] {
        return Array(transactions.values)
    }
    
    public func getActiveTransactions() async -> [STOMPTransaction] {
        return transactions.values.filter { $0.isActive }
    }
    
    public func getCommitedTransactions() async -> [STOMPTransaction] {
        return transactions.values.filter { $0.state == .committed }
    }
}
