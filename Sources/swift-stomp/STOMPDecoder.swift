//
//  STOMPDecoder.swift
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

public final class STOMPDecoder: Sendable {
    
    
    /*COMMAND
     header1:value1
     header2:value2
     
     Body^@
     */
    public class func decode(_ frame: String) async throws -> STOMPFrame {
        
        // Split the frame into lines
        let lines = frame.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Ensure the frame is not empty
        guard !lines.isEmpty else {
            throw STOMPError.invalidFirstLine("Empty frame")
        }
        
        // Command
        guard let firstLine = lines.first, !firstLine.isEmpty else {
            throw STOMPError.invalidFirstLine("Empty first line")
        }
        
        guard let command = STOMPCommand(rawValue: firstLine) else {
            throw STOMPError.invalidCommand(firstLine)
        }
        
        // Headers
        let headerLines = lines.dropFirst()
        guard let index = headerLines.firstIndex(of: "") else {
            throw STOMPError.invalidFirstLine("No empty line found after headers")
        }
        
        var headerConfiguration = STOMPHeaderConfiguration()
        
        for line in headerLines.prefix(upTo: index) {
            let headerComponents = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            
            // Ensure there are at least two components (key and value)
            guard headerComponents.count >= 2 else {
                throw STOMPError.invalidFrame("Invalid header format: \(line)")
            }
            
            let key = headerComponents[0]
            let value = headerComponents[1]
            
            // Log the parsed header for debugging
            print("Parsed header: \(key) = \(value)")
            
            switch STOMPHeaders(rawValue: key) {
            case .contentLength:
                headerConfiguration.contentLength = value
            case .contentType:
                headerConfiguration.contentType = value
            case .acceptVersion:
                headerConfiguration.acceptVersion = value
            case .host:
                headerConfiguration.host = value
            case .login:
                headerConfiguration.login = value
            case .passcode:
                headerConfiguration.passcode = value
            case .heartbeat:
                let heartbeatComponents = value.components(separatedBy: ",")
                guard heartbeatComponents.count == 2,
                      let send = Int(heartbeatComponents[0]),
                      let receive = Int(heartbeatComponents[1]) else {
                    throw STOMPError.invalidHeaderValue("heart-beat", value)
                }
                headerConfiguration.heartbeat = STOMPHeartbeat(send: send, receive: receive)
            case .version:
                headerConfiguration.version = value
            case .session:
                headerConfiguration.session = value
            case .server:
                headerConfiguration.server = value
            case .destination:
                headerConfiguration.destination = value
            case .id:
                headerConfiguration.id = value
            case .ack:
                guard let ack = ACKMode(rawValue: value) else {
                    throw STOMPError.invalidACK(value)
                }
                headerConfiguration.ack = ack
            case .transaction:
                headerConfiguration.transaction = value
            case .receipt:
                headerConfiguration.receipt = value
            case .messageId:
                headerConfiguration.messageId = value
            case .subscription:
                headerConfiguration.subscription = value
            case .receiptId:
                headerConfiguration.receiptId = value
            case .message:
                headerConfiguration.message = value
            case .customHeaders:
                // Handle custom headers if needed
                headerConfiguration.customHeaders?[key] = value
            default:
                // Unknown header, add to custom headers
                if headerConfiguration.customHeaders == nil {
                    headerConfiguration.customHeaders = [:]
                }
                headerConfiguration.customHeaders?[key] = value
            }
        }
        
        // Body
        if headerLines.count > index {
            let bodyIndex = index + 1
            let bodyLines = headerLines[bodyIndex...]
            let body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for null terminator and handle base64 if necessary
            let trimmedBody = body.hasSuffix("\0") ? String(body.dropLast()) : body
            
            let bodyType: BodyType
            if let data = Data(base64Encoded: trimmedBody) {
                bodyType = .data(data)
            } else {
                bodyType = .string(trimmedBody)
            }
            
            return STOMPFrame(command: command, configuration: headerConfiguration, body: bodyType)
        } else {
            return STOMPFrame(command: command, configuration: headerConfiguration)
        }
    }
    
}
