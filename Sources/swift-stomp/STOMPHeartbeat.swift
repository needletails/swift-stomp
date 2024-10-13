//
//  STOMPHeartbeat.swift
//  
//
//  Created by Cole M on 5/3/23.
//

import Foundation


public struct STOMPHeartbeat: Sendable {
    public let send: Int
    public let receive: Int
    
    var description: String {
        "\(send), \(receive)"
    }
    
    public init(send: Int, receive: Int) {
        self.send = send
        self.receive = receive
    }
}
