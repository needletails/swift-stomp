//
//  STOMPHeartbeat.swift
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
