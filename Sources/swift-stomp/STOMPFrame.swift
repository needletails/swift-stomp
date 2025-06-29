//
//  STOMPFrame.swift
//  swift-stomp
//
//  Created by Cole M on 4/6/23.
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

public enum BodyType: Sendable {
    case string(String), data(Data)
}

public struct STOMPFrame: Sendable {
    
    var command: STOMPCommand
    var headers: [String: String] = [:]
    var body: BodyType?
    
    init(command: STOMPCommand, configuration: STOMPHeaderConfiguration, body: BodyType? = nil) {

        if let customHeaders = configuration.customHeaders {
            self.headers = customHeaders
        }
        //Adding headers for the indicated command
        switch command {
            
            /// A STOMP client initiates the stream or TCP connection to the server by sending the CONNECT frame:
            /// CONNECT
            ///
            /// **
            /// accept-version:1.2
            /// host:stomp.github.org
            ///
            /// ^@
            ///**
            ///
            /// If the server accepts the connection attempt it will respond with a CONNECTED frame:
            ///
            /// **
            /// CONNECTED
            /// version:1.2
            ///
            /// ^@
            /// **
            ///
            /// The server can reject any connection attempt. The server SHOULD respond back with an ERROR frame explaining why the connection was rejected and then close the connection.
        case .CONNECT:
            //Required
            assert(configuration.acceptVersion != nil, "accept-version header is required")
            assert(configuration.host != nil, "host header is required")
            /// The versions of the STOMP protocol the client supports.
            self.headers[STOMPHeaders.acceptVersion.description] = configuration.acceptVersion
            /// The name of a virtual host that the client wishes to connect to. It is recommended clients set this to the host name that the socket was established against, or to any name of their choosing. If this header does not match a known virtual host, servers supporting virtual hosting MAY select a default virtual host or reject the connection.
            self.headers[STOMPHeaders.host.description] = configuration.host
            
            //Optional
            /// The user identifier used to authenticate against a secured STOMP server.
            self.headers[STOMPHeaders.login.description] = configuration.login
            /// The password used to authenticate against a secured STOMP server.
            self.headers[STOMPHeaders.passcode.description] = configuration.passcode
            /// The Heart-beating settings.
            self.headers[STOMPHeaders.heartbeat.description] = configuration.heartbeat?.description
            
            /// The SEND frame sends a message to a destination in the messaging system. It has one REQUIRED header, destination, which indicates where to send the message. The body of the SEND frame is the message to be sent.
            ///
            /// For example:
            ///
            ///**
            /// SEND
            /// destination:/queue/a
            /// content-type:text/plain
            ///
            /// hello queue a
            /// ^@
            ///**
            ///
            ///This sends a message to a destination named /queue/a. Note that STOMP treats this destination as an opaque string and no delivery semantics are assumed by the name of a destination. You should consult your STOMP server's documentation to find out how to construct a destination name which gives you the delivery semantics that your application needs.
            /// The reliability semantics of the message are also server specific and will depend on the destination value being used and the other message headers such as the transaction header or other server specific message headers.
            /// SEND supports a transaction header which allows for transactional sends.
            /// SEND frames SHOULD include a content-length header and a content-type header if a body is present.
            /// An application MAY add any arbitrary user defined headers to the SEND frame. User defined headers are typically used to allow consumers to filter messages based on the application defined headers using a selector on a SUBSCRIBE frame. The user defined headers MUST be passed through in the MESSAGE frame.
            /// If the server cannot successfully process the SEND frame for any reason, the server MUST send the client an ERROR frame and then close the connection.
        case .SEND:
            //Required
            assert(configuration.destination != nil, "destination header is required")
            self.headers[STOMPHeaders.destination.description] = configuration.destination
            
            if body != nil {
                assert(configuration.contentLength != nil, "content-length header is required")
                assert(configuration.contentType != nil, "content-type header is required")
                self.headers[STOMPHeaders.contentLength.description] = configuration.contentLength
                self.headers[STOMPHeaders.contentType.description] = configuration.contentType
            }
            
            //Optional
            self.headers[STOMPHeaders.transaction.description] = configuration.transaction
            
            /// The SUBSCRIBE frame is used to register to listen to a given destination. Like the SEND frame, the SUBSCRIBE frame requires a destination header indicating the destination to which the client wants to subscribe. Any messages received on the subscribed destination will henceforth be delivered as MESSAGE frames from the server to the client. The ack header controls the message acknowledgment mode.
            ///
            /// Example:
            ///
            /// **
            /// SUBSCRIBE
            /// id:0
            /// destination:/queue/foo
            /// ack:client
            ///
            /// ^@
            ///**
            ///
            /// If the server cannot successfully create the subscription, the server MUST send the client an ERROR frame and then close the connection.
            /// STOMP servers MAY support additional server specific headers to customize the delivery semantics of the subscription. Consult your server's documentation for details.
            ///
            /// *SUBSCRIBE id Header*
            
            /// Since a single connection can have multiple open subscriptions with a server, an id header MUST be included in the frame to uniquely identify the subscription. The id header allows the client and server to relate subsequent MESSAGE or UNSUBSCRIBE frames to the original subscription.
            /// Within the same connection, different subscriptions MUST use different subscription identifiers.
            ///
            /// *SUBSCRIBE ack Header*
            
            /// The valid values for the ack header are auto, client, or client-individual. If the header is not set, it defaults to auto.
            /// When the ack mode is auto, then the client does not need to send the server ACK frames for the messages it receives. The server will assume the client has received the message as soon as it sends it to the client. This acknowledgment mode can cause messages being transmitted to the client to get dropped.
            /// When the ack mode is client, then the client MUST send the server ACK frames for the messages it processes. If the connection fails before a client sends an ACK frame for the message the server will assume the message has not been processed and MAY redeliver the message to another client. The ACK frames sent by the client will be treated as a cumulative acknowledgment. This means the acknowledgment operates on the message specified in the ACK frame and all messages sent to the subscription before the ACK'ed message.
            /// In case the client did not process some messages, it SHOULD send NACK frames to tell the server it did not consume these messages.
            /// When the ack mode is client-individual, the acknowledgment operates just like the client acknowledgment mode except that the ACK or NACK frames sent by the client are not cumulative. This means that an ACK or NACK frame for a subsequent message MUST NOT cause a previous message to get acknowledged.
        case .SUBSCRIBE:
            //Required
            assert(configuration.destination != nil, "destination header is required")
            assert(configuration.id != nil, "id header is required")
            self.headers[STOMPHeaders.destination.description] = configuration.destination
            
            /// Within the same connection, different subscriptions MUST use different subscription identifiers.
            self.headers[STOMPHeaders.id.description] = configuration.id
            
            //Optional
            
            /// Controls message acknowledgement mode
            self.headers[STOMPHeaders.ack.description] = configuration.ack.description
            
            /// The UNSUBSCRIBE frame is used to remove an existing subscription. Once the subscription is removed the STOMP connections will no longer receive messages from that subscription.
            /// Since a single connection can have multiple open subscriptions with a server, an id header MUST be included in the frame to uniquely identify the subscription to remove. This header MUST match the subscription identifier of an existing subscription.
            ///
            /// Example:
            ///
            /// **
            /// UNSUBSCRIBE
            /// id:0
            ///
            ///^@
            ///**
            ///
        case .UNSUBSCRIBE:
            //Required
            assert(configuration.id != nil, "id header is required")
            self.headers[STOMPHeaders.id.description] = configuration.id
            
            //Optional
            //none
            
            /// BEGIN is used to start a transaction. Transactions in this case apply to sending and acknowledging - any messages sent or acknowledged during a transaction will be processed atomically based on the transaction.
            /// The transaction header is REQUIRED, and the transaction identifier will be used for SEND, COMMIT, ABORT, ACK, and NACK frames to bind them to the named transaction. Within the same connection, different transactions MUST use different transaction identifiers.
            /// Any started transactions which have not been committed will be implicitly aborted if the client sends a DISCONNECT frame or if the TCP connection fails for any reason.
        case .BEGIN:
            //Required
            assert(configuration.transaction != nil, "transaction header is required")
            self.headers[STOMPHeaders.transaction.description] = configuration.transaction
            
            //Optional
            //none
            
            /// COMMIT is used to commit a transaction in progress.
            /// The transaction header is REQUIRED and MUST specify the identifier of the transaction to commit.
        case .COMMIT:
            //Required
            assert(configuration.transaction != nil, "transacation header is required")
            self.headers[STOMPHeaders.transaction.description] = configuration.transaction
            
            //Optional
            //none
            
            /// ABORT is used to roll back a transaction in progress.
            /// The transaction header is REQUIRED and MUST specify the identifier of the transaction to abort.
        case .ABORT:
            //Required
            assert(configuration.transaction != nil, "transaction header is required")
            self.headers[STOMPHeaders.transaction.description] = configuration.transaction
            
            //Optional
            //none
            
            
            /// ACK is used to acknowledge consumption of a message from a subscription using client or client-individual acknowledgment. Any messages received from such a subscription will not be considered to have been consumed until the message has been acknowledged via an ACK.
            /// The ACK frame MUST include an id header matching the ack header of the MESSAGE being acknowledged. Optionally, a transaction header MAY be specified, indicating that the message acknowledgment SHOULD be part of the named transaction.
            ///
            /// **
            /// ACK
            /// id:12345
            /// transaction:tx1
            ///
            /// ^@
            /// **
            ///
        case .ACK:
            //Required
            assert(configuration.id != nil, "id header is required")
            self.headers[STOMPHeaders.id.description] = configuration.id
            
            //Optional
            self.headers[STOMPHeaders.transaction.description] = configuration.transaction
            
            ///NACK is the opposite of ACK. It is used to tell the server that the client did not consume the message. The server can then either send the message to a different client, discard it, or put it in a dead letter queue. The exact behavior is server specific.
            /// NACK takes the same headers as ACK: id (REQUIRED) and transaction (OPTIONAL).
            /// NACK applies either to one single message (if the subscription's ack mode is client-individual) or to all messages sent before and not yet ACK'ed or NACK'ed (if the subscription's ack mode is client).
        case .NACK:
            //Required
            assert(configuration.id != nil, "id header is required")
            self.headers[STOMPHeaders.id.description] = configuration.id
            
            //Optional
            self.headers[STOMPHeaders.transaction.description] = configuration.transaction
            
            /// A client can disconnect from the server at anytime by closing the socket but there is no guarantee that the previously sent frames have been received by the server. To do a graceful shutdown, where the client is assured that all previous frames have been received by the server, the client SHOULD:
            /// send a DISCONNECT frame with a receipt header set.
            ///
            /// Example:
            ///
            /// **
            /// DISCONNECT
            /// receipt:77
            /// ^@
            ///**
            /// wait for the RECEIPT frame response to the DISCONNECT.
            ///
            ///  Example:
            ///
            ///**
            /// RECEIPT
            /// receipt-id:77
            /// ^@
            /// **
            ///
            /// close the socket.
            ///
            /// Note that, if the server closes its end of the socket too quickly, the client might never receive the expected RECEIPT frame. See the Connection Lingering section for more information.
            /// Clients MUST NOT send any more frames after the DISCONNECT frame is sent.
        case .DISCONNECT:
            //Required
            //none
            
            //Optional
            self.headers[STOMPHeaders.receipt.description] = configuration.receipt
            
        case .CONNECTED:
            // Server response to CONNECT - no required headers for client processing
            self.headers[STOMPHeaders.version.description] = configuration.version
            self.headers[STOMPHeaders.session.description] = configuration.session
            self.headers[STOMPHeaders.server.description] = configuration.server
            self.headers[STOMPHeaders.heartbeat.description] = configuration.heartbeat?.description
            
        case .MESSAGE:
            // Server sends MESSAGE frames to clients with subscriptions
            assert(configuration.destination != nil, "destination header is required")
            assert(configuration.messageId != nil, "message-id header is required")
            assert(configuration.subscription != nil, "subscription header is required")
            
            self.headers[STOMPHeaders.destination.description] = configuration.destination
            self.headers[STOMPHeaders.messageId.description] = configuration.messageId
            self.headers[STOMPHeaders.subscription.description] = configuration.subscription
            self.headers[STOMPHeaders.ack.description] = configuration.ack.description
            self.headers[STOMPHeaders.contentLength.description] = configuration.contentLength
            self.headers[STOMPHeaders.contentType.description] = configuration.contentType
            
        case .RECEIPT:
            // Server response to frames with receipt header
            assert(configuration.receiptId != nil, "receipt-id header is required")
            self.headers[STOMPHeaders.receiptId.description] = configuration.receiptId
            
        case .ERROR:
            // Server error response
            self.headers[STOMPHeaders.version.description] = configuration.version
            self.headers[STOMPHeaders.contentType.description] = configuration.contentType
            self.headers[STOMPHeaders.contentLength.description] = configuration.contentLength
            self.headers[STOMPHeaders.message.description] = configuration.message
        }
        
        if self.headers.contains(where: { $0.key != STOMPHeaders.contentLength.description }), let contentLength = configuration.contentLength {
            self.headers[STOMPHeaders.contentLength.description] = contentLength
        }
        if self.headers.contains(where: { $0.key != STOMPHeaders.contentType.description }), let contentType = configuration.contentType {
            self.headers[STOMPHeaders.contentType.description] = contentType
        }
        if self.headers.contains(where: { $0.key != STOMPHeaders.receipt.description }), let receipt = configuration.receipt {
            //CONNECT Cannot contain arbitrary receipet value
            if command != .CONNECT {
                self.headers[STOMPHeaders.receipt.description] = receipt
            }
        }
        
        self.command = command
        self.body = body
    }
}
