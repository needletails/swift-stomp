//
//  STOMPInboundHandler.swift
//  
//
//  Created by Cole M on 5/3/23.
//

import Foundation

protocol STOMPInboundHandler: Sendable {
    func processStompFrame(_ frame: String) async throws
}

//extension STOMPInboundHandler {
//    func processStompFrame(_ frame: STOMPFrame) async throws {
//        switch frame.command {
//        case .SEND:
//            break
//        case .SUBSCRIBE:
//            break
//        case .UNSUBSCRIBE:
//            break
//        case .BEGIN:
//            break
//        case .COMMIT:
//            break
//        case .ABORT:
//            break
//        case .ACK:
//            break
//        case .NACK:
//            break
//        case .DISCONNECT:
//            break
//        case .CONNECT:
//            break
//        }
//    }
//}
