//
//  STOMPCommand.swift
//  
//
//  Created by Cole M on 5/3/23.
//

import Foundation


public enum STOMPCommand: String, Sendable {
    case SEND, SUBSCRIBE, UNSUBSCRIBE, BEGIN, COMMIT, ABORT, ACK, NACK, DISCONNECT, CONNECT
}
