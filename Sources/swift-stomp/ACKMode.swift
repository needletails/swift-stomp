//
//  ACKMode.swift
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


public enum ACKMode: String, Sendable {
    case auto, client, clientIndividual
    
    var description: String {
        switch self {
        case .auto:
            return "auto"
        case .client:
            return "client"
        case .clientIndividual:
            return "client-individual"
        }
    }
}
