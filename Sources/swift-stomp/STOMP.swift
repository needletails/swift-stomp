import Foundation

public protocol StompProtocol: AnyObject, Sendable {
    func connect(_ string: String) async throws
    func send(_ string: String) async throws
    func subscribe(_ string: String) async throws
    func unsubscribe(_ string: String) async throws
    func begin(_ string: String) async throws
    func commit(_ string: String) async throws
    func abort(_ string: String) async throws
    func acknowgledge(_ string: String) async throws
    func negativelyAcknowgledge(_ string: String) async throws
    func disconnected(_ string: String) async throws
}
