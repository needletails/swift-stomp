//
//  STOMPDecoder.swift
//  
//
//  Created by Cole M on 5/3/23.
//

import Foundation

enum STOMPErrors: Error {
    case invalidCommand, invalidFirstLine, invalidACK, invalidBody
}

public final class STOMPDecoder: Sendable {
    
    
    /*COMMAND
     header1:value1
     header2:value2
     
     Body^@
     */
    public class func decode(_ frame: String) async throws -> STOMPFrame {
        
        var command: STOMPCommand?
        var headerConfiguration = STOMPHeaderConfiguration()
        var lines = frame.components(separatedBy: "\n")
        
        if lines.first!.isEmpty {
            lines.removeFirst()
        }
        
        //Command
        guard let firstLine = lines.first else { throw STOMPErrors.invalidFirstLine }
        command = STOMPCommand(rawValue: firstLine)
        guard let command = command else { throw STOMPErrors.invalidCommand }
        
        //Headers
        // We cound have an endless list of Headers, search for next line that is empty, then we want to iterate over that array of lines to construct our header
        let newArray = lines.dropFirst()
        guard let index = newArray.firstIndex(of: "") else { throw STOMPErrors.invalidFirstLine }
        
        for line in Array(newArray.prefix(index - 1)) {
            let headerComponents = line.components(separatedBy: ":")
            switch STOMPHeaders(rawValue: String(headerComponents[0])) {
            case .contentLength:
                headerConfiguration.contentLength = String(headerComponents[1])
            case .contentType:
                headerConfiguration.contentType = String(headerComponents[1])
            case .acceptVersion:
                headerConfiguration.acceptVersion = String(headerComponents[1])
            case .host:
                headerConfiguration.host = String(headerComponents[1])
            case .login:
                headerConfiguration.login = String(headerComponents[1])
            case .passcode:
                headerConfiguration.passcode = String(headerComponents[1])
            case .heartbeat:
                let heartbeatComponents = String(headerComponents[1]).components(separatedBy: ",")
                headerConfiguration.heartbeat = STOMPHeartbeat(send: Int(heartbeatComponents[0]) ?? 0, receive: Int(heartbeatComponents[1]) ?? 0)
            case .version:
                headerConfiguration.version = String(headerComponents[1])
            case .session:
                headerConfiguration.session = String(headerComponents[1])
            case .server:
                headerConfiguration.server = String(headerComponents[1])
            case .destination:
                headerConfiguration.destination = String(headerComponents[1])
            case .id:
                headerConfiguration.id = String(headerComponents[1])
            case .ack:
                guard let ack = ACKMode(rawValue: String(headerComponents[1])) else { throw STOMPErrors.invalidACK }
                headerConfiguration.ack = ack
            case .transaction:
                headerConfiguration.transaction = String(headerComponents[1])
            case .receipt:
                headerConfiguration.receipt = String(headerComponents[1])
            case .messageId:
                headerConfiguration.messageId = String(headerComponents[1])
            case .subscription:
                headerConfiguration.subscription = String(headerComponents[1])
            case .receiptId:
                headerConfiguration.receiptId = String(headerComponents[1])
            case .message:
                headerConfiguration.message = String(headerComponents[1])
            case .customHeaders:
                let customHeaders = String(headerComponents[1]).components(separatedBy: ",")
                var tempDict = [String:String]()
                for dict in customHeaders {
                    let seperatedDict = dict.components(separatedBy: ":")
                    tempDict[seperatedDict[0]] = seperatedDict[1]
                }
                headerConfiguration.customHeaders = tempDict
            default:
                break
            }
        }
        
        
        
        if newArray.count > index {
            //Body
            var body: BodyType?
            let bodyIndex = index + 1
            var bodyLine = newArray[bodyIndex]
            if bodyLine.hasSuffix("\0") {
                bodyLine = bodyLine.replacingOccurrences(of: "\0", with: "")
            }
            if let data = Data(base64Encoded: bodyLine){
                body = .data(data)
            } else {
                body = .string(bodyLine)
            }
            guard let body = body else { throw STOMPErrors.invalidBody }
            return STOMPFrame(command: command, configuration: headerConfiguration, body:body)
        } else {
            return STOMPFrame(command: command, configuration: headerConfiguration)
        }
    }
}
