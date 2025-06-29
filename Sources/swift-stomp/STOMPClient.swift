//
//  STOMPClient.swift
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

public protocol TransportBridge: AnyObject, Sendable {
    func passData(_ string: String) async throws
    func close() async throws
}

public protocol STOMPClientDelegate: AnyObject, Sendable {
    func onConnected(connectionInfo: STOMPConnectionInfo) async
    func onDisconnected() async
    func onError(_ error: STOMPError) async
    func onMessageReceived(_ message: STOMPMessage) async
    func onReceiptReceived(_ receiptId: String) async
}

public actor STOMPClient: STOMPHeartbeatDelegate {
    // MARK: - Properties
    
    private let configuration: STOMPClientConfiguration
    private weak var delegate: STOMPClientDelegate?
    private weak var transportBridge: TransportBridge?
    
    // State management
    private var connectionState: STOMPConnectionState = .disconnected
    private var connectionInfo: STOMPConnectionInfo?
    private var reconnectAttempts = 0
    private var reconnectTimer: Timer?
    
    // Managers
    private let transactionManager = STOMPTransactionManager()
    private var heartbeatManager: STOMPHeartbeatManager?
    private var subscriptions: [String: STOMPSubscription] = [:]
    private var pendingReceipts: Set<String> = []
    
    // Message tracking
    private var messageCounter = 0
    private var receiptCounter = 0
    
    // MARK: - Initialization
    
    public init(configuration: STOMPClientConfiguration, delegate: STOMPClientDelegate? = nil) {
        self.configuration = configuration
        self.delegate = delegate
    }
    
    // MARK: - Public API
    
    public func connect(transportBridge: TransportBridge) async throws {
        guard !connectionState.isConnecting else {
            throw STOMPError.connectionFailed("Already connecting")
        }
        
        self.transportBridge = transportBridge
        connectionState = .connecting
        
        do {
            let connectFrame = try await createConnectFrame()
            let encodedFrame = try await STOMPEncoder.encode(connectFrame)
            
            try await transportBridge.passData(encodedFrame)
            
            // Wait for CONNECTED frame response
            // This would typically be handled by the transport layer
            // For now, we'll simulate a successful connection
            await handleConnected()
            
        } catch {
            connectionState = .error(error as? STOMPError ?? STOMPError.connectionFailed(error.localizedDescription))
            throw error
        }
    }
    
    public func disconnect() async throws {
        guard connectionState.isConnected else {
            throw STOMPError.connectionFailed("Not connected")
        }
        
        guard let transportBridge = transportBridge else {
            throw STOMPError.transportError("Transport bridge is nil")
        }
        
        connectionState = .disconnecting
        
        // Stop heartbeat
        heartbeatManager?.stop()
        
        // Send DISCONNECT frame
        let disconnectFrame = try await createDisconnectFrame()
        let encodedFrame = try await STOMPEncoder.encode(disconnectFrame)
        
        try await transportBridge.passData(encodedFrame)
        
        // Wait for RECEIPT if requested
        if let receiptId = disconnectFrame.headers[STOMPHeaders.receipt.description] {
            pendingReceipts.insert(receiptId)
            // In a real implementation, we'd wait for the RECEIPT frame
        }
        
        await handleDisconnected()
    }
    
    public func subscribe(
        destination: String,
        id: String,
        ackMode: ACKMode = .auto,
        selector: String? = nil,
        customHeaders: [String: String] = [:]
    ) async throws {
        guard connectionState.isConnected else {
            throw STOMPError.connectionFailed("Not connected")
        }
        
        guard let transportBridge = transportBridge else {
            throw STOMPError.transportError("Transport bridge is nil")
        }
        
        let subscription = STOMPSubscription(
            id: id,
            destination: destination,
            ackMode: ackMode,
            selector: selector,
            customHeaders: customHeaders
        )
        
        let subscribeFrame = try await createSubscribeFrame(subscription: subscription)
        let encodedFrame = try await STOMPEncoder.encode(subscribeFrame)
        
        try await transportBridge.passData(encodedFrame)
        
        subscriptions[id] = subscription
    }
    
    public func unsubscribe(id: String) async throws {
        guard connectionState.isConnected else {
            throw STOMPError.connectionFailed("Not connected")
        }
        
        guard let transportBridge = transportBridge else {
            throw STOMPError.transportError("Transport bridge is nil")
        }
        
        guard subscriptions[id] != nil else {
            throw STOMPError.subscriptionFailed("Subscription not found")
        }
        
        let unsubscribeFrame = try await createUnsubscribeFrame(id: id)
        let encodedFrame = try await STOMPEncoder.encode(unsubscribeFrame)
        
        try await transportBridge.passData(encodedFrame)
        
        subscriptions.removeValue(forKey: id)
    }
    
    public func send(
        destination: String,
        body: BodyType,
        contentType: String? = nil,
        transaction: String? = nil,
        customHeaders: [String: String] = [:]
    ) async throws {
        guard connectionState.isConnected else {
            throw STOMPError.connectionFailed("Not connected")
        }
        
        guard let transportBridge = transportBridge else {
            throw STOMPError.transportError("Transport bridge is nil")
        }
        
        let sendFrame = try await createSendFrame(
            destination: destination,
            body: body,
            contentType: contentType,
            transaction: transaction,
            customHeaders: customHeaders
        )
        
        let encodedFrame = try await STOMPEncoder.encode(sendFrame)
        
        try await transportBridge.passData(encodedFrame)
        
        // Track in transaction if needed
        if let transactionId = transaction {
            let messageId = "msg-\(messageCounter)"
            messageCounter += 1
            _ = await transactionManager.addMessageToTransaction(transactionId: transactionId, messageId: messageId)
        }
    }
    
    public func acknowledge(messageId: String, transaction: String? = nil) async throws {
        guard connectionState.isConnected else {
            throw STOMPError.connectionFailed("Not connected")
        }
        
        guard let transportBridge = transportBridge else {
            throw STOMPError.transportError("Transport bridge is nil")
        }
        
        let ackFrame = try await createAckFrame(messageId: messageId, transaction: transaction)
        let encodedFrame = try await STOMPEncoder.encode(ackFrame)
        
        try await transportBridge.passData(encodedFrame)
        
        // Track in transaction if needed
        if let transactionId = transaction {
            _ = await transactionManager.addAcknowledgmentToTransaction(transactionId: transactionId, messageId: messageId)
        }
        
        // Update subscription state
        for (subscriptionId, var subscription) in subscriptions {
            if subscription.isMessagePending(messageId) {
                subscription.acknowledgeMessage(messageId)
                subscriptions[subscriptionId] = subscription
                break
            }
        }
    }
    
    public func negativeAcknowledge(messageId: String, transaction: String? = nil) async throws {
        guard connectionState.isConnected else {
            throw STOMPError.connectionFailed("Not connected")
        }
        
        guard let transportBridge = transportBridge else {
            throw STOMPError.transportError("Transport bridge is nil")
        }
        
        let nackFrame = try await createNackFrame(messageId: messageId, transaction: transaction)
        let encodedFrame = try await STOMPEncoder.encode(nackFrame)
        
        try await transportBridge.passData(encodedFrame)
        
        // Update subscription state
        for (subscriptionId, var subscription) in subscriptions {
            if subscription.isMessagePending(messageId) {
                subscription.negativeAcknowledgeMessage(messageId)
                subscriptions[subscriptionId] = subscription
                break
            }
        }
    }
    
    public func beginTransaction(id: String, timeout: TimeInterval = 30.0) async -> STOMPTransaction {
        return await transactionManager.beginTransaction(id: id, timeout: timeout)
    }
    
    public func commitTransaction(id: String) async throws {
        guard connectionState.isConnected else {
            throw STOMPError.connectionFailed("Not connected")
        }
        
        guard let transportBridge = transportBridge else {
            throw STOMPError.transportError("Transport bridge is nil")
        }
        
        let commitFrame = try await createCommitFrame(id: id)
        let encodedFrame = try await STOMPEncoder.encode(commitFrame)
        
        try await transportBridge.passData(encodedFrame)
        
        _ = await transactionManager.commitTransaction(id: id)
    }
    
    public func abortTransaction(id: String) async throws {
        guard connectionState.isConnected else {
            throw STOMPError.connectionFailed("Not connected")
        }
        
        guard let transportBridge = transportBridge else {
            throw STOMPError.transportError("Transport bridge is nil")
        }
        
        let abortFrame = try await createAbortFrame(id: id)
        let encodedFrame = try await STOMPEncoder.encode(abortFrame)
        
        try await transportBridge.passData(encodedFrame)
        
        _ = await transactionManager.abortTransaction(id: id)
    }
    
    // MARK: - Frame Processing
    
    public func processIncomingFrame(_ frameString: String) async throws {
        let frame = try await STOMPDecoder.decode(frameString)
        
        switch frame.command {
        case .CONNECTED:
            await handleConnectedFrame(frame)
            
        case .MESSAGE:
            await handleMessageFrame(frame)
            
        case .RECEIPT:
            await handleReceiptFrame(frame)
            
        case .ERROR:
            await handleErrorFrame(frame)
            
        default:
            // Ignore other frame types for now
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func createConnectFrame() async throws -> STOMPFrame {
        let config = STOMPHeaderConfiguration(
            acceptVersion: configuration.acceptVersion,
            host: configuration.virtualHost,
            login: configuration.login,
            passcode: configuration.passcode,
            heartbeat: configuration.heartbeat,
            customHeaders: configuration.customHeaders
        )
        
        return STOMPFrame(command: .CONNECT, configuration: config)
    }
    
    private func createDisconnectFrame() async throws -> STOMPFrame {
        let receiptId = "receipt-\(receiptCounter)"
        receiptCounter += 1
        
        let config = STOMPHeaderConfiguration(
            receipt: receiptId
        )
        
        return STOMPFrame(command: .DISCONNECT, configuration: config)
    }
    
    private func createSubscribeFrame(subscription: STOMPSubscription) async throws -> STOMPFrame {
        var config = STOMPHeaderConfiguration(
            destination: subscription.destination,
            id: subscription.id,
            ack: subscription.ackMode
        )
        
        if let selector = subscription.selector {
            config.customHeaders = ["selector": selector]
        }
        
        if !subscription.customHeaders.isEmpty {
            if config.customHeaders == nil {
                config.customHeaders = [:]
            }
            config.customHeaders?.merge(subscription.customHeaders) { _, new in new }
        }
        
        return STOMPFrame(command: .SUBSCRIBE, configuration: config)
    }
    
    private func createUnsubscribeFrame(id: String) async throws -> STOMPFrame {
        let config = STOMPHeaderConfiguration(id: id)
        return STOMPFrame(command: .UNSUBSCRIBE, configuration: config)
    }
    
    private func createSendFrame(
        destination: String,
        body: BodyType,
        contentType: String?,
        transaction: String?,
        customHeaders: [String: String]
    ) async throws -> STOMPFrame {
        var config = STOMPHeaderConfiguration(destination: destination)
        
        if let contentType = contentType {
            config.contentType = contentType
        } else {
            config.contentType = configuration.defaultContentType
        }
        
        if let transaction = transaction {
            config.transaction = transaction
        }
        
        if !customHeaders.isEmpty {
            config.customHeaders = customHeaders
        }
        
        // Add content length for body
        switch body {
        case .string(let string):
            config.contentLength = "\(string.utf8.count)"
        case .data(let data):
            config.contentLength = "\(data.count)"
        }
        
        return STOMPFrame(command: .SEND, configuration: config, body: body)
    }
    
    private func createAckFrame(messageId: String, transaction: String?) async throws -> STOMPFrame {
        var config = STOMPHeaderConfiguration(id: messageId)
        if let transaction = transaction {
            config.transaction = transaction
        }
        return STOMPFrame(command: .ACK, configuration: config)
    }
    
    private func createNackFrame(messageId: String, transaction: String?) async throws -> STOMPFrame {
        var config = STOMPHeaderConfiguration(id: messageId)
        if let transaction = transaction {
            config.transaction = transaction
        }
        return STOMPFrame(command: .NACK, configuration: config)
    }
    
    private func createCommitFrame(id: String) async throws -> STOMPFrame {
        let config = STOMPHeaderConfiguration(transaction: id)
        return STOMPFrame(command: .COMMIT, configuration: config)
    }
    
    private func createAbortFrame(id: String) async throws -> STOMPFrame {
        let config = STOMPHeaderConfiguration(transaction: id)
        return STOMPFrame(command: .ABORT, configuration: config)
    }
    
    private func handleConnectedFrame(_ frame: STOMPFrame) async {
        let sessionId = frame.headers[STOMPHeaders.session.description]
        let serverVersion = frame.headers[STOMPHeaders.version.description]
        let serverName = frame.headers[STOMPHeaders.server.description]
        
        var heartbeat: STOMPHeartbeat?
        if let heartbeatString = frame.headers[STOMPHeaders.heartbeat.description] {
            let components = heartbeatString.components(separatedBy: ",")
            if components.count == 2 {
                heartbeat = STOMPHeartbeat(
                    send: Int(components[0]) ?? 0,
                    receive: Int(components[1]) ?? 0
                )
            }
        }
        
        connectionInfo = STOMPConnectionInfo(
            sessionId: sessionId,
            serverVersion: serverVersion,
            serverName: serverName,
            heartbeat: heartbeat
        )
        
        await handleConnected()
    }
    
    private func handleMessageFrame(_ frame: STOMPFrame) async {
        let message = STOMPMessage(from: frame)
        
        // Update subscription state
        if let subscriptionId = frame.headers[STOMPHeaders.subscription.description],
           var subscription = subscriptions[subscriptionId] {
            subscription.addMessage(frame)
            subscriptions[subscriptionId] = subscription
        }
        
        await delegate?.onMessageReceived(message)
    }
    
    private func handleReceiptFrame(_ frame: STOMPFrame) async {
        if let receiptId = frame.headers[STOMPHeaders.receiptId.description] {
            pendingReceipts.remove(receiptId)
            await delegate?.onReceiptReceived(receiptId)
        }
    }
    
    private func handleErrorFrame(_ frame: STOMPFrame) async {
        let errorMessage = frame.headers[STOMPHeaders.message.description] ?? "Unknown error"
        let error = STOMPError.serverError(errorMessage)
        
        connectionState = .error(error)
        await delegate?.onError(error)
    }
    
    private func handleConnected() async {
        connectionState = .connected
        reconnectAttempts = 0
        
        // Start heartbeat if configured
        if let heartbeat = connectionInfo?.heartbeat, heartbeat.send > 0 || heartbeat.receive > 0 {
            heartbeatManager = STOMPHeartbeatManager(
                heartbeat: heartbeat,
                timeout: configuration.heartbeatTimeout,
                delegate: self
            )
            heartbeatManager?.start()
        }
        
        await delegate?.onConnected(connectionInfo: connectionInfo ?? STOMPConnectionInfo())
    }
    
    private func handleDisconnected() async {
        connectionState = .disconnected
        heartbeatManager?.stop()
        heartbeatManager = nil
        connectionInfo = nil
        
        await delegate?.onDisconnected()
    }
    
    // MARK: - STOMPHeartbeatDelegate
    
    public func sendHeartbeat() async throws {
        // Send a newline character as heartbeat
        guard let transportBridge = transportBridge else {
            throw STOMPError.transportError("Transport bridge is nil")
        }
        try await transportBridge.passData("\n")
    }
    
    public func onHeartbeatTimeout() async {
        let error = STOMPError.heartbeatTimeout
        connectionState = .error(error)
        await delegate?.onError(error)
    }
    
    // MARK: - Public Properties
    
    public var isConnected: Bool {
        return connectionState.isConnected
    }
    
    public var currentState: STOMPConnectionState {
        return connectionState
    }
    
    public var currentConnectionInfo: STOMPConnectionInfo? {
        return connectionInfo
    }
    
    public var activeSubscriptions: [STOMPSubscription] {
        return Array(subscriptions.values)
    }
    
    public func activeTransactions() async -> [STOMPTransaction] {
        return await transactionManager.getActiveTransactions()
    }
    
    public func commitedTransactions() async -> [STOMPTransaction] {
        return await transactionManager.getCommitedTransactions()
    }
}
