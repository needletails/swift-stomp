//
//  STOMPEncoder.swift
//  
//
//  Created by Cole M on 5/3/23.
//

import Foundation

public final class STOMPEncoder: @unchecked Sendable {
    public class func encode(_ frame: STOMPFrame) async throws -> String {
        var encoded = ""
        let command = frame.command.rawValue + "\n"
        let headers = frame.headers
        let body = frame.body
        
        encoded += command
        
        for header in headers {
            encoded += "\(header.key):\(header.value)\n"
        }
        
        
        
        switch body {
        case .string(let string):
            encoded += "\n\(string)"
        case .data(let data):
            let base64Data = data.base64EncodedString()
            encoded += "\n\(base64Data)"
        default:
            encoded += "\n"
        }
        return encoded
    }
}
