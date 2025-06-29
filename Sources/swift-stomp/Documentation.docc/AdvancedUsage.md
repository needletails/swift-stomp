# Advanced Usage

Learn about advanced features like transactions, custom acknowledgment modes, and performance optimization.

## Transactions

### Basic Transaction Usage

```swift
// Begin a transaction
let transaction = client.beginTransaction(id: "tx-1")

// Send messages in the transaction
try await client.send(
    destination: "/queue/orders",
    body: .string("Order 1"),
    transaction: "tx-1"
)

try await client.send(
    destination: "/queue/notifications",
    body: .string("Order 1 created"),
    transaction: "tx-1"
)

// Commit the transaction
try await client.commitTransaction(id: "tx-1")
```

### Transaction with Error Handling

```swift
let transaction = client.beginTransaction(id: "batch-send")

do {
    try await client.send(
        destination: "/queue/orders",
        body: .string("Order 1"),
        transaction: "batch-send"
    )
    
    try await client.send(
        destination: "/queue/notifications",
        body: .string("Order 1 created"),
        transaction: "batch-send"
    )
    
    // Commit all messages
    try await client.commitTransaction(id: "batch-send")
    print("✅ All messages sent successfully")
    
} catch {
    // Abort on error
    try await client.abortTransaction(id: "batch-send")
    print("❌ Transaction aborted: \(error)")
}
```

### Message Processing with Transactions

```swift
func onMessageReceived(_ message: STOMPMessage) async {
    let transaction = client.beginTransaction(id: "process-\(message.id)")
    
    do {
        // Process the message
        await processMessage(message)
        
        // Acknowledge in transaction
        try await client.acknowledge(messageId: message.id, transaction: "process-\(message.id)")
        
        // Send response
        try await client.send(
            destination: "/queue/responses",
            body: .string("Processed: \(message.id)"),
            transaction: "process-\(message.id)"
        )
        
        // Commit transaction
        try await client.commitTransaction(id: "process-\(message.id)")
        
    } catch {
        // Abort on error
        try await client.abortTransaction(id: "process-\(message.id)")
        print("❌ Message processing failed: \(error)")
    }
}
```

## Custom Acknowledgment Modes

### Client Acknowledgment (Cumulative)

```swift
// Subscribe with client acknowledgment
try await client.subscribe(
    destination: "/queue/orders",
    id: "orders-sub",
    ackMode: .client
)

// In delegate
func onMessageReceived(_ message: STOMPMessage) async {
    // Process message
    await processMessage(message)
    
    // Acknowledge this message and all previous messages
    try await client.acknowledge(messageId: message.id)
}
```

### Client Individual Acknowledgment

```swift
// Subscribe with client individual acknowledgment
try await client.subscribe(
    destination: "/queue/notifications",
    id: "notifications-sub",
    ackMode: .clientIndividual
)

// In delegate
func onMessageReceived(_ message: STOMPMessage) async {
    // Process message
    await processMessage(message)
    
    // Acknowledge only this specific message
    try await client.acknowledge(messageId: message.id)
}
```

## Message Selectors

### Filtering Messages

```swift
// Subscribe with selector for high priority messages
try await client.subscribe(
    destination: "/queue/orders",
    id: "high-priority",
    selector: "priority = 'high'"
)

// Subscribe with complex selector
try await client.subscribe(
    destination: "/queue/orders",
    id: "urgent-us",
    selector: "(priority = 'urgent' OR priority = 'high') AND region = 'US'"
)
```

## Custom Headers

### Sending with Custom Headers

```swift
try await client.send(
    destination: "/queue/orders",
    body: .string("Order data"),
    customHeaders: [
        "priority": "high",
        "customer-id": "12345",
        "order-type": "express",
        "expires": "3600000",  // 1 hour in milliseconds
        "persistent": "true"
    ]
)
```

### Subscription with Custom Headers

```swift
try await client.subscribe(
    destination: "/queue/orders",
    id: "customer-orders",
    customHeaders: [
        "client-id": "order-processor",
        "subscription-type": "durable"
    ]
)
```

## Heartbeat Configuration

### Optimal Heartbeat Settings

```swift
let configuration = STOMPClientConfiguration(
    host: "localhost",
    port: 61613,
    
    // Heartbeat settings for production
    heartbeatSendInterval: 10.0,     // Send every 10 seconds
    heartbeatReceiveInterval: 10.0,  // Expect every 10 seconds
    heartbeatTimeout: 30.0           // Timeout after 30 seconds
)
```

### Disable Heartbeats

```swift
let configuration = STOMPClientConfiguration(
    host: "localhost",
    port: 61613,
    
    // Disable heartbeats
    heartbeatSendInterval: 0.0,
    heartbeatReceiveInterval: 0.0
)
```

## Performance Optimization

### Message Batching

```swift
func sendBatchMessages(_ messages: [String]) async throws {
    let transaction = client.beginTransaction(id: "batch-\(UUID().uuidString)")
    
    for message in messages {
        try await client.send(
            destination: "/queue/batch",
            body: .string(message),
            transaction: transaction.id
        )
    }
    
    try await client.commitTransaction(id: transaction.id)
}
```

### Connection Pooling

```swift
class STOMPConnectionPool {
    private var clients: [STOMPClient] = []
    private let maxConnections: Int
    
    init(maxConnections: Int = 5) {
        self.maxConnections = maxConnections
    }
    
    func getClient() async throws -> STOMPClient {
        // Implementation for connection pooling
        // This is a simplified example
        if let availableClient = clients.first(where: { $0.isConnected }) {
            return availableClient
        }
        
        // Create new client if needed
        let config = STOMPClientConfiguration(host: "localhost", port: 61613)
        let client = STOMPClient(configuration: config, delegate: self)
        clients.append(client)
        return client
    }
}
```

## Error Recovery

### Automatic Reconnection

```swift
class RobustSTOMPClient {
    private let client: STOMPClient
    private var reconnectTask: Task<Void, Never>?
    
    func connect() async {
        do {
            try await client.connect(transportBridge: transportBridge)
        } catch STOMPError.connectionFailed(let reason) {
            print("Connection failed: \(reason)")
            await scheduleReconnect()
        } catch STOMPError.authenticationFailed(let reason) {
            print("Authentication failed: \(reason)")
            // Handle authentication issues
        } catch {
            print("Unexpected error: \(error)")
        }
    }
    
    private func scheduleReconnect() async {
        reconnectTask?.cancel()
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            await connect()
        }
    }
}
```

### Message Processing Error Handling

```swift
func onMessageReceived(_ message: STOMPMessage) async {
    do {
        // Process message
        await processMessage(message)
        
        // Acknowledge on success
        try await client.acknowledge(messageId: message.id)
        
    } catch {
        // Negative acknowledge on failure
        do {
            try await client.negativeAcknowledge(messageId: message.id)
        } catch {
            print("❌ Failed to NACK message: \(error)")
        }
    }
}
```

## Monitoring and Debugging

### Connection Monitoring

```swift
class MonitoringDelegate: STOMPClientDelegate {
    func onConnected(connectionInfo: STOMPConnectionInfo) async {
        print("✅ Connected at \(Date())")
        print("Session: \(connectionInfo.sessionId ?? "Unknown")")
        print("Server: \(connectionInfo.serverName ?? "Unknown")")
        
        if let heartbeat = connectionInfo.heartbeat {
            print("Heartbeat: send=\(heartbeat.send)ms, receive=\(heartbeat.receive)ms")
        }
    }
    
    func onError(_ error: STOMPError) async {
        print("🚨 Error at \(Date()): \(error.localizedDescription)")
        
        // Log error for monitoring
        logError(error)
    }
    
    private func logError(_ error: STOMPError) {
        // Implementation for error logging
    }
}
```

### Performance Monitoring

```swift
func onMessageReceived(_ message: STOMPMessage) async {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // Process message
    await processMessage(message)
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let processingTime = endTime - startTime
    
    print("Message processing time: \(processingTime) seconds")
    
    // Acknowledge
    try await client.acknowledge(messageId: message.id)
}
```

## Best Practices

### Memory Management

```swift
class STOMPManager {
    private weak var client: STOMPClient?
    
    func setupClient() {
        let config = STOMPClientConfiguration(host: "localhost", port: 61613)
        client = STOMPClient(configuration: config, delegate: self)
    }
    
    // Use weak references to prevent retain cycles
    func cleanup() {
        client = nil
    }
}
```

### Resource Cleanup

```swift
class STOMPViewController: UIViewController {
    private var client: STOMPClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSTOMPClient()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Cleanup when view disappears
        Task {
            try? await client?.disconnect()
        }
    }
}
```
