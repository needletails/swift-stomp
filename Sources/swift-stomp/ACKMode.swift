//
//  ACKMode.swift
//  
//
//  Created by Cole M on 5/3/23.
//

import Foundation


//TODO: On Message Receive Handle ACK/NACK According to spec
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
