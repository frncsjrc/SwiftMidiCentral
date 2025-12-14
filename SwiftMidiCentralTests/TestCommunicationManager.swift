//
//  TestLocalManager.swift
//  SwiftMidiCentralTests
//
//  Created by François Jean Raymond CLÉMENT on 23/11/2025.
//

import Testing
import OSLog

@testable import SwiftMidiCentral

@MainActor
@Suite("Communication Manager Tests")
struct TestCommunicationManager {
    
    @Test("Default constructor") func defaultConstructor() async throws {
        let testee = CommunicationManager()
        
        #expect(testee.remotes.isEmpty)
        #expect(testee.selectedDestination == nil)
        #expect(testee.lastSource.isEmpty)
        #expect(testee.lastMessages.isEmpty)
        #expect(testee.outputBuffer.isEmpty)
        #expect(testee.central.isScanning == false)
    }
    
    @Test("Central") func central() async throws {
        let logStartDate = Date()
        Logger.swiftMidiCentralSubsystem = "TestLocalManager.Central"

        let expectedIdentifiers = CommunicationManager.remoteSamples.keys.compactMap {
            UUID(uuidString: $0)!
        }

        try #require(expectedIdentifiers.count == 3)
        
        let testee = CommunicationManager()
        
        testee.central.startScanning()
        
        #expect(testee.selectedDestination == nil)
        #expect(testee.lastSource.isEmpty)
        #expect(testee.lastMessages.isEmpty)
        #expect(testee.outputBuffer.isEmpty)
        
        #expect(testee.central.isScanning == true)
        #expect(testee.remotes.count == 3)
        
        for identifier in expectedIdentifiers {
            let details = testee.remotes.first(where: { $0.id == identifier })
            #expect(details != nil)

            let expectedDetails = CommunicationManager.remoteSamples[
                identifier.uuidString
            ]
            #expect(expectedDetails != nil)

            #expect(details?.name == expectedDetails?.name)
            #expect(details?.state == .offline)
            
            try? testee.central.connect(to: identifier)
            let update1 = testee.remotes.first(where: { $0.id == identifier })
            #expect(update1?.state == .connected)
            
            // MARK - Check re-scanning does not overwrite state
            testee.central.startScanning()
            let update2 = testee.remotes.first(where: { $0.id == identifier })
            #expect(update2?.name == expectedDetails?.name)
            #expect(update2?.state == .connected)
            
            try? testee.central.disconnect(from: identifier)
            let update3 = testee.remotes.first(where: { $0.id == identifier })
            #expect(update3?.state == .disconnected)
        }
        
        testee.central.stopScanning()
        
        let dummyPeripheral = UUID(
            uuidString: "00000000-0000-0000-0000-000000000001"
        )!
        
        #expect(!testee.central.isScanning)

        let expectedMessages: [String] = [
            Localized.localCentralCannotConnectToPeripheral(with: dummyPeripheral),
            Localized.localCentralCannotDisconnectFromPeripheral(with: dummyPeripheral)
        ]

        let logStore = try! OSLogStore(scope: .currentProcessIdentifier)
        
        let initialLogEntries = try! logStore.getEntries(
            at: logStore.position(date: logStartDate),
            matching: Logger.connectivityFilter
        )
        for (index, entry) in initialLogEntries.enumerated() {
            guard index < expectedMessages.count else {
                print(
                    "Unexpected log entry at index \(index): \(entry.composedMessage)"
                )
                continue
            }
            #expect(entry.composedMessage == expectedMessages[index])
        }
        
        try? testee.central.connect(to: dummyPeripheral)
        try? testee.central.disconnect(from: dummyPeripheral)
        
        let updatedLogEntries = try! logStore.getEntries(
            at: logStore.position(date: logStartDate),
            matching: Logger.connectivityFilter
        )
        for (index, entry) in updatedLogEntries.enumerated() {
            guard index < expectedMessages.count else {
                print(
                    "Unexpected log entry at index \(index): \(entry.composedMessage)"
                )
                continue
            }
            #expect(entry.composedMessage == expectedMessages[index])
        }
    }
    
    @Test("Usage") func usage() async throws {
        let logStartDate = Date()
        Logger.swiftMidiCentralSubsystem = "TestLocalManager.Usage"

        let expectedIdentifiers = CommunicationManager.remoteSamples.keys.compactMap {
            UUID(uuidString: $0)!
        }

        try #require(expectedIdentifiers.count == 3)
        
        let testee = CommunicationManager()
        
        testee.central.startScanning()
        
        #expect(testee.selectedDestination == nil)
        #expect(testee.lastSource.isEmpty)
        #expect(testee.lastMessages.isEmpty)
        #expect(testee.outputBuffer.isEmpty)
        
        #expect(testee.central.isScanning == true)
        #expect(testee.remotes.count == 3)
        
        let dummyPeripheral = UUID(
            uuidString: "00000000-0000-0000-0000-000000000001"
        )!

        let expectedMessages: [String] = [
            Localized.localCentralCannotConnectToPeripheral(with: dummyPeripheral),
            Localized.localCentralCannotDisconnectFromPeripheral(with: dummyPeripheral)
        ]

        let logStore = try! OSLogStore(scope: .currentProcessIdentifier)
        
        let initialLogEntries = try! logStore.getEntries(
            at: logStore.position(date: logStartDate),
            matching: Logger.connectivityFilter
        )
        for (index, entry) in initialLogEntries.enumerated() {
            guard index < expectedMessages.count else {
                print(
                    "Unexpected log entry at index \(index): \(entry.composedMessage)"
                )
                continue
            }
            #expect(entry.composedMessage == expectedMessages[index])
        }
        
        try? testee.central.connect(to: dummyPeripheral)
        try? testee.central.disconnect(from: dummyPeripheral)
        
        let updatedLogEntries = try! logStore.getEntries(
            at: logStore.position(date: logStartDate),
            matching: Logger.connectivityFilter
        )
        for (index, entry) in updatedLogEntries.enumerated() {
            guard index < expectedMessages.count else {
                print(
                    "Unexpected log entry at index \(index): \(entry.composedMessage)"
                )
                continue
            }
            #expect(entry.composedMessage == expectedMessages[index])
        }
    }

}
