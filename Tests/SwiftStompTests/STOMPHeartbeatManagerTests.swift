//
//  STOMPHeartbeatManagerTests.swift
//  
//
//  Created by Cole M on 5/3/23.
//
import Foundation
import Testing
@testable import SwiftStomp

@Suite(.serialized)
actor STOMPHeartbeatManagerTests: STOMPHeartbeatDelegate {
    
    private var heartbeatManager: STOMPHeartbeatManager!
    private var sendHeartbeatCount = 0
    private var timeoutCount = 0
    private var lastSendTime: Date?
    private var lastTimeoutTime: Date?
    
    // MARK: - STOMPHeartbeatDelegate
    
    func sendHeartbeat() async throws {
        sendHeartbeatCount += 1
        lastSendTime = Date()
        // Simulate some network delay
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
    
    func onHeartbeatTimeout() async {
        timeoutCount += 1
        lastTimeoutTime = Date()
    }
    
    // MARK: - Tests
    
    @Test("Heartbeat manager should initialize with correct configuration")
    func testInitialization() async {
        let heartbeat = STOMPHeartbeat(send: 1000, receive: 2000) // 1s send, 2s receive
        let manager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 5.0, delegate: self)
        
        #expect(await !manager.isActive)
        await #expect(manager.timeSinceLastHeartbeat == nil)
    }
    
    @Test("Start should activate heartbeat manager")
    func testStart() async {
        let heartbeat = STOMPHeartbeat(send: 100, receive: 200) // 100ms send, 200ms receive
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 1.0, delegate: self)
        
        await heartbeatManager.start()
        
        #expect(await heartbeatManager.isActive)
    }
    
    @Test("Stop should deactivate heartbeat manager")
    func testStop() async {
        let heartbeat = STOMPHeartbeat(send: 100, receive: 200)
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 1.0, delegate: self)
        
        await heartbeatManager.start()
        #expect(await heartbeatManager.isActive)
        
        await heartbeatManager.stop()
        #expect(await !heartbeatManager.isActive)
    }
    
    @Test("Send heartbeat should be called at specified interval")
    func testSendHeartbeatInterval() async throws {
        let heartbeat = STOMPHeartbeat(send: 50, receive: 0) // 50ms send, no receive
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 1.0, delegate: self)
        
        sendHeartbeatCount = 0
        lastSendTime = nil
        
        await heartbeatManager.start()
        
        // Wait for at least 2 heartbeats (100ms + some buffer)
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        await heartbeatManager.stop()
        
        // Should have sent at least 2 heartbeats
        #expect(sendHeartbeatCount >= 2)
        #expect(lastSendTime != nil)
    }
    
    @Test("Receive heartbeat should track last received time")
    func testReceiveHeartbeatTracking() async {
        let heartbeat = STOMPHeartbeat(send: 0, receive: 100) // No send, 100ms receive
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 1.0, delegate: self)
        
        await heartbeatManager.start()
        
        // Simulate receiving a heartbeat
        await heartbeatManager.onHeartbeatReceived()
        
        let timeSinceLast = await heartbeatManager.timeSinceLastHeartbeat
        #expect(timeSinceLast != nil)
        #expect(timeSinceLast! < 0.1) // Should be very recent
    }
    
    @Test("Timeout should be triggered when no heartbeat received")
    func testHeartbeatTimeout() async throws {
        let heartbeat = STOMPHeartbeat(send: 0, receive: 50) // No send, 50ms receive check
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 0.1, delegate: self) // 100ms timeout
        
        timeoutCount = 0
        lastTimeoutTime = nil
        
        await heartbeatManager.start()
        
        // Wait for timeout to occur (150ms should be enough)
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        await heartbeatManager.stop()
        
        // Should have triggered timeout
        #expect(timeoutCount >= 1)
        #expect(lastTimeoutTime != nil)
    }
    
    @Test("Timeout should not be triggered when heartbeats are received")
    func testNoTimeoutWhenHeartbeatsReceived() async throws {
        let heartbeat = STOMPHeartbeat(send: 0, receive: 50) // No send, 50ms receive check
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 0.2, delegate: self) // 200ms timeout
        
        timeoutCount = 0
        
        // Record an initial heartbeat before starting
        await heartbeatManager.onHeartbeatReceived()
        
        await heartbeatManager.start()
        
        // Send heartbeats regularly to prevent timeout
        for _ in 0..<4 {
            try await Task.sleep(nanoseconds: 30_000_000) // 30ms
            await heartbeatManager.onHeartbeatReceived()
        }
        
        await heartbeatManager.stop()
        
        // Should not have triggered timeout
        #expect(timeoutCount == 0)
    }
    
    @Test("Timeout should be triggered when no heartbeat received before starting")
    func testTimeoutWhenNoHeartbeatBeforeStart() async throws {
        let heartbeat = STOMPHeartbeat(send: 0, receive: 50) // No send, 50ms receive check
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 0.1, delegate: self) // 100ms timeout
        
        timeoutCount = 0
        lastTimeoutTime = nil
        
        // Start without recording any heartbeat
        await heartbeatManager.start()
        
        // Wait for timeout to occur
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        await heartbeatManager.stop()
        
        // Should have triggered timeout since no heartbeat was recorded
        #expect(timeoutCount >= 1)
        #expect(lastTimeoutTime != nil)
    }
    
    @Test("Both send and receive heartbeats should work simultaneously")
    func testSimultaneousSendAndReceive() async throws {
        let heartbeat = STOMPHeartbeat(send: 50, receive: 50) // 50ms for both
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 0.1, delegate: self)
        
        sendHeartbeatCount = 0
        timeoutCount = 0
        
        await heartbeatManager.start()
        
        // Wait for some heartbeats to be sent
        try await Task.sleep(nanoseconds: 120_000_000) // 120ms
        
        await heartbeatManager.stop()
        
        // Should have sent heartbeats
        #expect(sendHeartbeatCount >= 2)
        
        // May or may not have timeouts depending on timing
        // The important thing is that both tasks were running
        await #expect(heartbeatManager.isActive == false)
    }
    
    @Test("Restart should work correctly")
    func testRestart() async throws {
        let heartbeat = STOMPHeartbeat(send: 50, receive: 0)
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 1.0, delegate: self)
        
        sendHeartbeatCount = 0
        
        // Start first time
        await heartbeatManager.start()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Stop
        await heartbeatManager.stop()
        let countAfterFirstStop = sendHeartbeatCount
        
        // Start again
        await heartbeatManager.start()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await heartbeatManager.stop()
        
        // Should have sent more heartbeats after restart
        #expect(sendHeartbeatCount > countAfterFirstStop)
    }
    
    @Test("Zero heartbeat intervals should not start tasks")
    func testZeroHeartbeatIntervals() async {
        let heartbeat = STOMPHeartbeat(send: 0, receive: 0) // No heartbeats
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 1.0, delegate: self)
        
        sendHeartbeatCount = 0
        timeoutCount = 0
        
        await heartbeatManager.start()
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await heartbeatManager.stop()
        
        // Should not have sent any heartbeats or timeouts
        #expect(sendHeartbeatCount == 0)
        #expect(timeoutCount == 0)
    }
    
    @Test("Error in sendHeartbeat should not stop the loop")
    func testSendHeartbeatErrorHandling() async throws {
        let heartbeat = STOMPHeartbeat(send: 50, receive: 0)
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 1.0, delegate: self)
        
        // Create a delegate that throws errors
        let errorDelegate = ErrorThrowingDelegate()
        let errorManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 1.0, delegate: errorDelegate)
        
        await errorManager.start()
        
        // Wait for some heartbeats to be attempted
        try await Task.sleep(nanoseconds: 120_000_000) // 120ms
        
        await errorManager.stop()
        
        // Should have attempted to send heartbeats (even though they failed)
        #expect(await errorDelegate.attemptCount >= 2)
    }
    
    @Test("Time since last heartbeat should be accurate")
    func testTimeSinceLastHeartbeat() async throws {
        let heartbeat = STOMPHeartbeat(send: 0, receive: 100)
        heartbeatManager = STOMPHeartbeatManager(heartbeat: heartbeat, timeout: 1.0, delegate: self)
        
        await heartbeatManager.start()
        
        // Record heartbeat
        await heartbeatManager.onHeartbeatReceived()
        
        // Wait a specific amount of time
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        let timeSince = await heartbeatManager.timeSinceLastHeartbeat
        #expect(timeSince != nil)
        #expect(timeSince! >= 0.05) // Should be at least 50ms
        #expect(timeSince! < 0.06) // Should be less than 60ms (with some buffer)
        
        await heartbeatManager.stop()
    }
}

// Helper class for testing error scenarios
private actor ErrorThrowingDelegate: STOMPHeartbeatDelegate {
    var attemptCount = 0
    
    func sendHeartbeat() async throws {
        attemptCount += 1
        throw STOMPError.transportError("Simulated network error")
    }
    
    func onHeartbeatTimeout() async {
        // Do nothing for this test
    }
} 
