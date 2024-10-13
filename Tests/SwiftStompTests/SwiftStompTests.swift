import XCTest
@testable import swift_stomp

final class SwiftStompTests: XCTestCase, TransportBridge, STOMPInboundHandler {
    
    weak var delegate: STOMPOutboundHandler?
    let outboundHandler = STOMPOutboundHandler()
    
    override func setUp() {
        delegate = outboundHandler
    }
    //TODO: Test Each Outbound command
    func testSTOMPConnection() async throws {
            outboundHandler.delegate = self
            
            let config = STOMPHeaderConfiguration(
                acceptVersion: "1",
                host: "host.someHost.com",
                login: "user1",
                passcode: "123",
                heartbeat: STOMPHeartbeat(send: 1, receive: 1)
            )
            let frame = STOMPFrame(command: .CONNECT, configuration: config)
            let string = try await STOMPEncoder.encode(frame)
            try await delegate?.connect(string)
    }
    
    func testSTOMPSendString() async throws {
            outboundHandler.delegate = self
            
            let message = "Some message to send"
            
            let config = STOMPHeaderConfiguration(
                contentLength: "\(message.utf8.count)",
                contentType: MIME(type: .text, subType: .plain).mime,
                destination: "destination/other-user"
            )

            let frame = STOMPFrame(command: .SEND, configuration: config, body: .string(message))
            let string = try await STOMPEncoder.encode(frame)
            try await delegate?.connect(string)
        }
    
    func testSTOMPSendData() async throws {
            outboundHandler.delegate = self
            
            let messageData = Data("Some message to send".utf8)
            
            let config = STOMPHeaderConfiguration(
                contentLength: "\(messageData.count)",
                contentType: MIME(type: .text, subType: .plain).mime,
                destination: "destination/other-user"
            )

            let frame = STOMPFrame(command: .SEND, configuration: config, body: .data(messageData))
            let encodedString = try await STOMPEncoder.encode(frame)
            try await delegate?.connect(encodedString)
        }

    
    func testDecodeFrame() async throws {
            outboundHandler.delegate = self
            
            let messageData = Data("Some message to send".utf8)
            
            let config = STOMPHeaderConfiguration(
                contentLength: "\(messageData.count)",
                contentType: MIME(type: .text, subType: .plain).mime,
                destination: "api/other-user"
            )

            let frame = STOMPFrame(command: .SEND, configuration: config, body: .data(messageData))
            let encodedString = try await STOMPEncoder.encode(frame)
            try await delegate?.send(encodedString)
        }

    
    //TODO: Test Each COMMAND's Frame requirements
    func processStompFrame(_ frame: String) async throws {
        let decodedFrame = try await STOMPDecoder.decode(frame)
        switch decodedFrame.command {
        case .SEND:
            break
        case .SUBSCRIBE:
            break
        case .UNSUBSCRIBE:
            break
        case .BEGIN:
            break
        case .COMMIT:
            break
        case .ABORT:
            break
        case .ACK:
            break
        case .NACK:
            break
        case .DISCONNECT:
            break
        case .CONNECT:
            break
        }
    }

    //We are transport agnostic
    func passData(_ string: String) async throws {
        //SEND IN TRANSPORT
        //For instance here is where we will send in a nio channel via channel.write
//         channel.writeAndFlush(string)
        try await processStompFrame(string)
        
    }
    
}
