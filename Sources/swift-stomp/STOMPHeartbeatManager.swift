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

public actor STOMPHeartbeatManager {
    private weak var delegate: STOMPHeartbeatDelegate?
    private let heartbeat: STOMPHeartbeat
    private let timeout: TimeInterval
    
    private var sendTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var lastReceivedHeartbeat: Date?
    private var isRunning = false
    
    public init(heartbeat: STOMPHeartbeat, timeout: TimeInterval = 30.0, delegate: STOMPHeartbeatDelegate? = nil) {
        self.heartbeat = heartbeat
        self.timeout = timeout
        self.delegate = delegate
    }
    
    public func start() {
        stop() // Stop any existing tasks
        
        isRunning = true
        
        // Start send task if we need to send heartbeats
        if heartbeat.send > 0 {
            sendTask = Task { [weak self] in
                guard let self else { return }
                await self.runSendHeartbeatLoop()
            }
        }
        
        // Start receive task if we expect to receive heartbeats
        if heartbeat.receive > 0 {
            receiveTask = Task { [weak self] in
                guard let self else { return }
                await self.runReceiveHeartbeatLoop()
            }
        }
    }
    
    public func stop() {
        isRunning = false
        sendTask?.cancel()
        sendTask = nil
        receiveTask?.cancel()
        receiveTask = nil
    }
    
    public func onHeartbeatReceived() {
        lastReceivedHeartbeat = Date()
    }
    
    private func runSendHeartbeatLoop() async {
        let interval = TimeInterval(heartbeat.send / 1000)
        
        while isRunning {
            do {
                try await delegate?.sendHeartbeat()
            } catch {
                // Log error but don't stop the loop
                print("Failed to send heartbeat: \(error)")
            }
            
            // Sleep for the heartbeat interval
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    }
    
    private func runReceiveHeartbeatLoop() async {
        let interval = TimeInterval(heartbeat.receive / 1000)
        
        while isRunning {
            await checkHeartbeatTimeout()
            
            // Sleep for the heartbeat interval
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    }
    
    private func checkHeartbeatTimeout() async {
        guard let lastReceived = lastReceivedHeartbeat else {
            // No heartbeat received yet, check if we've exceeded the timeout
            if Date().timeIntervalSince(Date().addingTimeInterval(-timeout)) > timeout {
                await delegate?.onHeartbeatTimeout()
            }
            return
        }
        
        if Date().timeIntervalSince(lastReceived) > timeout {
            await delegate?.onHeartbeatTimeout()
        }
    }
    
    public var isActive: Bool {
        return isRunning
    }
    
    public var timeSinceLastHeartbeat: TimeInterval? {
        guard let lastReceived = lastReceivedHeartbeat else { return nil }
        return Date().timeIntervalSince(lastReceived)
    }
} 
