//
//  STOMPHeartbeatManager.swift
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

public protocol STOMPHeartbeatDelegate: AnyObject, Sendable {
    func sendHeartbeat() async throws
    func onHeartbeatTimeout() async
}

public class STOMPHeartbeatManager: @unchecked Sendable {
    private weak var delegate: STOMPHeartbeatDelegate?
    private let heartbeat: STOMPHeartbeat
    private let timeout: TimeInterval
    
    private var sendTimer: Timer?
    private var receiveTimer: Timer?
    private var lastReceivedHeartbeat: Date?
    
    public init(heartbeat: STOMPHeartbeat, timeout: TimeInterval = 30.0, delegate: STOMPHeartbeatDelegate? = nil) {
        self.heartbeat = heartbeat
        self.timeout = timeout
        self.delegate = delegate
    }
    
    public func start() {
        stop() // Stop any existing timers
        
        // Start send timer if we need to send heartbeats
        if heartbeat.send > 0 {
            sendTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(heartbeat.send / 1000), repeats: true) { [weak self] _ in
                Task {
                    await self?.sendHeartbeat()
                }
            }
        }
        
        // Start receive timer if we expect to receive heartbeats
        if heartbeat.receive > 0 {
            receiveTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(heartbeat.receive / 1000), repeats: true) { [weak self] _ in
                self?.checkHeartbeatTimeout()
            }
        }
    }
    
    public func stop() {
        sendTimer?.invalidate()
        sendTimer = nil
        receiveTimer?.invalidate()
        receiveTimer = nil
    }
    
    public func onHeartbeatReceived() {
        lastReceivedHeartbeat = Date()
    }
    
    private func sendHeartbeat() async {
        do {
            try await delegate?.sendHeartbeat()
        } catch {
            // Log error but don't stop the timer
            print("Failed to send heartbeat: \(error)")
        }
    }
    
    private func checkHeartbeatTimeout() {
        guard let lastReceived = lastReceivedHeartbeat else {
            // No heartbeat received yet, check if we've exceeded the timeout
            if Date().timeIntervalSince(Date().addingTimeInterval(-timeout)) > timeout {
                Task {
                    await delegate?.onHeartbeatTimeout()
                }
            }
            return
        }
        
        if Date().timeIntervalSince(lastReceived) > timeout {
            Task {
                await delegate?.onHeartbeatTimeout()
            }
        }
    }
    
    public var isActive: Bool {
        return sendTimer != nil || receiveTimer != nil
    }
    
    public var timeSinceLastHeartbeat: TimeInterval? {
        guard let lastReceived = lastReceivedHeartbeat else { return nil }
        return Date().timeIntervalSince(lastReceived)
    }
} 