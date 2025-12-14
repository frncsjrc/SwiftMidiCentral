//
//  TestRemoteDetails.swift
//  SouthBridgeTests
//
//  Created by François Jean Raymond CLÉMENT on 12/10/2025.
//

import Foundation
import Testing

@testable import SwiftMidiCentral

@MainActor
@Suite("Remote Details Tests")
struct TestRemoteDetails {

    @Test("Default constructor") func DefaultConstructor() async throws {
        let name = "testee"

        let testee = RemoteDetails(name: name)
        
        #expect(testee.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(testee.name == name)
        #expect(testee.advertisedName == nil)
        #expect(testee.peripheral == nil)
        #expect(testee.source == nil)
        #expect(testee.destination == nil)
        #expect(!testee.enableReception)
        #expect(testee.state == .offline)
        #expect(testee.manufacturer == nil)
        #expect(testee.model == nil)
        #expect(testee.description == name)
    }

    @Test("Custom constructor") func CustomConstructor() async throws {
        let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let name = "testee"
        let advertisedName = "nickname"
        let source: UInt32 = 12345
        let destination: UInt32 = 67890
        let enableReception = true
        let state = RemoteState.connected
        let manufacturer = "Test Inc."
        let model = "Mark I"

        // there is no way to test midiPeripheral to be anything else than nil
        let testee = RemoteDetails(
            id: id,
            name: name,
            advertisedName: advertisedName,
            source: source,
            destination: destination,
            enableReception: enableReception,
            state: state,
            manufacturer: manufacturer,
            model: model
        )

        #expect(testee.id == id)
        #expect(testee.name == name)
        #expect(testee.advertisedName == advertisedName)
        #expect(testee.peripheral == nil)
        #expect(testee.source == source)
        #expect(testee.destination == destination)
        #expect(testee.enableReception == enableReception)
        #expect(testee.state == state)
        #expect(testee.manufacturer == manufacturer)
        #expect(testee.model == model)
        #expect(testee.description == "\(name) - \(advertisedName)")
    }

}
