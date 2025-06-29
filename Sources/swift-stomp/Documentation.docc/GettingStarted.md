# Getting Started

Learn how to integrate the Swift STOMP SDK into your project.

## Overview

The Swift STOMP SDK provides a complete STOMP 1.2 client implementation for Swift applications. This guide will help you get started with basic setup and usage.

## Installation

### Swift Package Manager

Add the Swift STOMP SDK to your project using Swift Package Manager:

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/needle-tail/swift-stomp.git`
3. Select the version you want to use
4. Click **Add Package**

Alternatively, add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/needle-tail/swift-stomp.git", from: "1.0.0")
]
```

## Requirements

- **iOS**: 18.0+
- **macOS**: 15.0+
- **Swift**: 6.0+
- **Xcode**: 15.0+

## Quick Start

### 1. Import the Framework

```swift
import SwiftStomp
```

### 2. Create Configuration

```swift
let configuration = STOMPClientConfiguration(
    host: "localhost",
    port: 61613,
    login: "username",
    passcode: "password"
)
```

### 3. Implement Transport Bridge

```swift
class WebSocketTransport: TransportBridge {
    private var webSocket: URLSessionWebSocketTask?
    
    func passData(_ string: String) async throws {
        let message = URLSessionWebSocketTask.Message.string(string)
        try await webSocket?.send(message)
    }
    
    func close() async throws {
        webSocket?.cancel()
    }
}
```

### 4. Create Client and Delegate

```swift
class MySTOMPDelegate: STOMPClientDelegate {
    func onConnected(connectionInfo: STOMPConnectionInfo) async {
        print("Connected to STOMP broker")
    }
    
    func onDisconnected() async {
        print("Disconnected from STOMP broker")
    }
    
    func onError(_ error: STOMPError) async {
        print("STOMP Error: \(error.localizedDescription)")
    }
    
    func onMessageReceived(_ message: STOMPMessage) async {
        print("Received message: \(message.bodyString ?? "")")
    }
    
    func onReceiptReceived(_ receiptId: String) async {
        print("Received receipt: \(receiptId)")
    }
}

let client = STOMPClient(configuration: configuration, delegate: MySTOMPDelegate())
```

### 5. Connect and Use

```swift
// Connect to broker
let transport = WebSocketTransport()
try await client.connect(transportBridge: transport)

// Subscribe to a destination
try await client.subscribe(
    destination: "/queue/test",
    id: "subscription-1"
)

// Send a message
try await client.send(
    destination: "/queue/test",
    body: .string("Hello, STOMP!")
)

// Disconnect when done
try await client.disconnect()
```

## Next Steps

- Check out <doc:AdvancedUsage> for advanced features like transactions and custom acknowledgment modes 
