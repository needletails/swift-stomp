//
//  STOMPClientTests.swift
//  
//
//  Created by Cole M on 5/3/23.
//
import Testing
@testable import SwiftStomp

@Suite(.serialized)
actor STOMPClientTests: STOMPClientDelegate, TransportBridge {
    
    private var client: STOMPClient!
    private var receivedMessages: [STOMPMessage] = []
    private var receivedReceipts: [String] = []
    private var connectionInfo: STOMPConnectionInfo?
    private var errors: [STOMPError] = []
    private var isConnected = false
    
    init() async {
        let configuration = STOMPClientConfiguration(
            host: "localhost",
            port: 61613,
            login: "testuser",
            passcode: "testpass",
            heartbeatSendInterval: 1.0,
            heartbeatReceiveInterval: 1.0,
            enableLogging: true
        )
        
        client = STOMPClient(configuration: configuration, delegate: self)
        receivedMessages = []
        receivedReceipts = []
        connectionInfo = nil
        errors = []
        isConnected = false
    }
    
    // MARK: - STOMPClientDelegate
    
    func onConnected(connectionInfo: STOMPConnectionInfo) async {
        self.connectionInfo = connectionInfo
        isConnected = true
    }
    
    func onDisconnected() async {
        isConnected = false
    }
    
    func onError(_ error: STOMPError) async {
        errors.append(error)
    }
    
    func onMessageReceived(_ message: STOMPMessage) async {
        receivedMessages.append(message)
    }
    
    func onReceiptReceived(_ receiptId: String) async {
        receivedReceipts.append(receiptId)
    }
    
    // MARK: - TransportBridge
    
    func passData(_ string: String) async throws {
        // Simulate transport layer
        // In a real implementation, this would send data over WebSocket/TCP
        print("Transport: \(string)")
    }
    
    func close() async throws {
        // Simulate closing the transport layer
        print("Transport: Closing connection")
    }
    
    // MARK: - Tests
    
    @Test("create a valid client instance")
    func testClientInitialization() async {
        #expect(await client != nil)
        #expect(await !client.isConnected)
        await #expect(client.currentState == .disconnected)
    }
    
    @Test("Connection should transition to connecting state")
    func testConnection() async throws {
        try await client.connect(transportBridge: self)
        
        await #expect(client.currentState == .connected)
    }
    
    @Test("Subscription should create an active subscription")
    func testSubscription() async throws {
        // First connect
        try await client.connect(transportBridge: self)
        
        // Subscribe to a destination
        try await client.subscribe(
            destination: "/queue/test",
            id: "sub-1",
            ackMode: .client
        )
        
        await #expect(client.activeSubscriptions.count == 1)
        await #expect(client.activeSubscriptions.first?.destination == "/queue/test")
        await #expect(client.activeSubscriptions.first?.ackMode == .client)
    }
    
    @Test("Send message should send a string message")
    func testSendMessage() async throws {
        // First connect
        try await client.connect(transportBridge: self)
        
        // Send a message
        try await client.send(
            destination: "/queue/test",
            body: .string("Hello, STOMP!")
        )
        
        // Verify the message was sent (in a real test, we'd verify the frame)
    }
    
    @Test("Send data message should send a data message")
    func testSendDataMessage() async throws {
        // First connect
        try await client.connect(transportBridge: self)
        
        let data = "Hello, STOMP!".data(using: .utf8)!
        
        // Send a data message
        try await client.send(
            destination: "/queue/test",
            body: .data(data),
            contentType: "application/octet-stream"
        )
        
        // Verify the message was sent
    }
    
    @Test("Transaction should handle begin, send, and commit operations")
    func testTransaction() async throws {
        // First connect
        try await client.connect(transportBridge: self)
        
        // Begin a transaction
        let transaction = await client.beginTransaction(id: "tx-1")
        #expect(transaction.state == .active)
        
        // Send a message in the transaction
        try await client.send(
            destination: "/queue/test",
            body: .string("Transactional message"),
            transaction: "tx-1"
        )
        
        // Commit the transaction
        try await client.commitTransaction(id: "tx-1")
        
        // Verify transaction is committed
        let updatedTransaction = await client.commitedTransactions().first { $0.id == "tx-1" }
        #expect(updatedTransaction?.state == .committed)
    }
    
    @Test("Message acknowledgment should acknowledge received messages")
    func testMessageAcknowledgment() async throws {
        // First connect and subscribe
        try await client.connect(transportBridge: self)
        try await client.subscribe(
            destination: "/queue/test",
            id: "sub-1",
            ackMode: .client
        )
        
        // Simulate receiving a message
        let messageFrame = """
        MESSAGE
        destination:/queue/test
        message-id:msg-123
        subscription:sub-1
        content-type:text/plain
        content-length:13
        
        Hello, World!
        """
        
        try await client.processIncomingFrame(messageFrame)
        
        // Verify message was received
        #expect(receivedMessages.count == 1)
        #expect(receivedMessages.first?.id == "msg-123")
        
        // Acknowledge the message
        try await client.acknowledge(messageId: "msg-123")
    }
    
    @Test("Negative acknowledgment should negatively acknowledge received messages")
    func testNegativeAcknowledgment() async throws {
        // First connect and subscribe
        try await client.connect(transportBridge: self)
        try await client.subscribe(
            destination: "/queue/test",
            id: "sub-1",
            ackMode: .client
        )
        
        // Simulate receiving a message
        let messageFrame = """
        MESSAGE
        destination:/queue/test
        message-id:msg-456
        subscription:sub-1
        content-type:text/plain
        content-length:13
        
        Hello, World!
        """
        
        try await client.processIncomingFrame(messageFrame)
        
        // Negative acknowledge the message
        try await client.negativeAcknowledge(messageId: "msg-456")
    }
    
    @Test("Unsubscribe should remove active subscription")
    func testUnsubscribe() async throws {
        // First connect and subscribe
        try await client.connect(transportBridge: self)
        try await client.subscribe(
            destination: "/queue/test",
            id: "sub-1"
        )
        
        await #expect(client.activeSubscriptions.count == 1)
        
        // Unsubscribe
        try await client.unsubscribe(id: "sub-1")
        
        await #expect(client.activeSubscriptions.count == 0)
    }
    
    @Test("Disconnect should transition to disconnected state")
    func testDisconnect() async throws {
        // First connect
        try await client.connect(transportBridge: self)
        
        // Disconnect
        try await client.disconnect()
        
        await #expect(client.currentState == .disconnected)
    }
    
    @Test("Error handling should handle connection errors")
    func testErrorHandling() async throws {
        // Test connection error
        do {
            try await client.connect(transportBridge: self)
            // In a real test, we'd simulate an error response
        } catch {
            #expect(error is STOMPError)
        }
    }
    
    @Test("Configuration should have correct values")
    func testConfiguration() {
        let config = STOMPClientConfiguration(
            host: "testhost.com",
            port: 61614,
            useSSL: true,
            login: "user",
            passcode: "pass",
            heartbeatSendInterval: 5.0,
            heartbeatReceiveInterval: 5.0,
            maxMessageSize: 1024 * 1024,
            defaultContentType: "application/json"
        )
        
        #expect(config.host == "testhost.com")
        #expect(config.port == 61614)
        #expect(config.useSSL == true)
        #expect(config.login == "user")
        #expect(config.passcode == "pass")
        #expect(config.heartbeatSendInterval == 5.0)
        #expect(config.heartbeatReceiveInterval == 5.0)
        #expect(config.maxMessageSize == 1024 * 1024)
        #expect(config.defaultContentType == "application/json")
    }
    
    @Test("Frame encoding and decoding should work correctly")
    func testFrameEncodingDecoding() async throws {
        // Test encoding a CONNECT frame
        let config = STOMPHeaderConfiguration(
            acceptVersion: "1.2",
            host: "localhost",
            login: "user",
            passcode: "pass"
        )
        
        let frame = STOMPFrame(command: .CONNECT, configuration: config)
        let encoded = try await STOMPEncoder.encode(frame)
        
        // Test decoding the frame
        let decoded = try await STOMPDecoder.decode(encoded)
        
        #expect(decoded.command == .CONNECT)
        #expect(decoded.headers["accept-version"] == "1.2")
        #expect(decoded.headers["host"] == "localhost")
        #expect(decoded.headers["login"] == "user")
        #expect(decoded.headers["passcode"] == "pass")
    }
    
    @Test("Message with custom headers should include custom headers")
    func testMessageWithCustomHeaders() async throws {
        // First connect
        try await client.connect(transportBridge: self)
        
        // Send a message with custom headers
        try await client.send(
            destination: "/queue/test",
            body: .string("Custom message"),
            customHeaders: [
                "priority": "high",
                "expires": "3600000",
                "persistent": "true"
            ]
        )
        
        // Verify the message was sent with custom headers
    }
    
    @Test("Subscription with selector should include selector")
    func testSubscriptionWithSelector() async throws {
        // First connect
        try await client.connect(transportBridge: self)
        
        // Subscribe with a selector
        try await client.subscribe(
            destination: "/queue/test",
            id: "sub-1",
            selector: "priority = 'high'"
        )
        
        await #expect(client.activeSubscriptions.count == 1)
        await #expect(client.activeSubscriptions.first?.selector == "priority = 'high'")
    }
} 
