//
//  TestRemoteState.swift
//  SouthBridgeTests
//
//  Created by François Jean Raymond CLÉMENT on 12/10/2025.
//

import Testing

@testable import SwiftMidiCentral

@Suite("Remote State Tests")
struct TestRemoteState {

    @Test("All Cases", arguments: RemoteState.allCases) func allCases(
        testee: RemoteState
    ) async throws {
        switch testee {
        case .offline:
            #expect(testee.rawValue == "offline")
        case .connected:
            #expect(testee.rawValue == "connected")
        case .disconnected:
            #expect(testee.rawValue == "disconnected")
        }
    }

}
