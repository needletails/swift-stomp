# Swift STOMP SDK - Production Documentation

## Quick Start

### Installation

```swift
// Add to Package.swift
dependencies: [
    .package(url: "https://github.com/needle-tail/swift-stomp.git", from: "1.0.0")
]
```

### Basic Usage

```swift
import SwiftStomp

// Configure client
let config = STOMPClientConfiguration(
    host: "your-broker.com",
    port: 61613,
    login: "username",
    passcode: "password"
)

// Create client with delegate
let client = STOMPClient(configuration: config, delegate: self)

// Connect
try await client.connect(transportBridge: transportBridge)

// Subscribe
try await client.subscribe(destination: "/queue/test", id: "sub-1")

// Send message
try await client.send(destination: "/queue/test", body: .string("Hello"))
```

## Documentation

- **[DocC Documentation](Sources/swift-stomp/Documentation.docc/Documentation.md)** - Complete API reference and guides
- **[Getting Started](Sources/swift-stomp/Documentation.docc/GettingStarted.md)** - Quick setup guide
- **[Basic Usage](Sources/swift-stomp/Documentation.docc/BasicUsage.md)** - Core usage examples
- **[Advanced Usage](Sources/swift-stomp/Documentation.docc/AdvancedUsage.md)** - Advanced features and patterns

## Key Features

✅ **STOMP 1.2 Protocol** - Full protocol compliance  
✅ **Async/Await Support** - Modern Swift concurrency  
✅ **Thread Safety** - Sendable conformance throughout  
✅ **Transaction Support** - BEGIN/COMMIT/ABORT operations  
✅ **Message Acknowledgment** - Auto/Client/Client-Individual modes  
✅ **Heartbeat Management** - Connection monitoring  
✅ **Error Handling** - Comprehensive error types  
✅ **Transport Agnostic** - Works with any transport layer  

## Production Checklist

### ✅ Code Quality
- [x] Async/await linter errors fixed
- [x] Thread safety implemented with Sendable
- [x] Memory leak prevention in delegates
- [x] Proper error handling throughout

### ✅ Documentation
- [x] DocC documentation system implemented
- [x] Comprehensive API documentation
- [x] Getting started guide
- [x] Advanced usage examples
- [x] Usage examples

### ✅ Testing
- [x] Unit tests included
- [x] Integration test examples
- [x] Error scenario coverage

### ✅ Configuration
- [x] Production-ready configuration options
- [x] Heartbeat timeout handling
- [x] Reconnection strategies
- [x] Logging configuration

## Support

- **Documentation**: [DocC Documentation](Sources/swift-stomp/Documentation.docc/Documentation.md)
- **Issues**: [GitHub Issues](https://github.com/needle-tail/swift-stomp/issues)
- **Contact**: support@needletails.com

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.

---

**Ready for Production** ✅ 