//
//  TestSwiftMidiCentralLog.swift
//  SwiftMidiCentralTests
//
//  Created by François Jean Raymond CLÉMENT on 19/10/2025.
//

import OSLog
import Testing

@testable import SwiftMidiCentral

@MainActor
@Suite("SwiftMidiCentral Log Tests")
struct TestSwiftMidiCentralLog {

    @Test("Usage") func usage() async throws {
        let logStartDate = Date()
        Logger.swiftMidiCentralSubsystem = "TestSwiftMidiCentralLog.Usage"
        let messages: [String] = [
            "This is a connectivity debug message",
            "This is a view cycle debug message",
            "This is an analytics debug message",
        ]

        Logger.connectivity.debug("\(messages[0])")
        Logger.viewCycle.debug("\(messages[1])")
        Logger.analytics.debug("\(messages[2])")

        let logStore = try! OSLogStore(scope: .currentProcessIdentifier)

        var logEntries = try! logStore.getEntries(
            at: logStore.position(date: logStartDate),
            matching: Logger.southBridgeFilter
        )
        for (index, entry) in logEntries.enumerated() {
            guard index < messages.count else {
                print("Unexpected log entry at index \(index): \(entry.composedMessage)")
                continue
            }
            #expect(entry.composedMessage == messages[index])
        }

        logEntries = try! logStore.getEntries(
            at: logStore.position(date: logStartDate),
            matching: Logger.connectivityFilter
        )
        for (index, entry) in logEntries.enumerated() {
            guard index == 0 else {
                print("Unexpected log entry at index \(index): \(entry.composedMessage)")
                continue
            }
            #expect(entry.composedMessage == messages[0])
        }

        logEntries = try! logStore.getEntries(
            at: logStore.position(date: logStartDate),
            matching: Logger.viewCycleFilter
        )
        for (index, entry) in logEntries.enumerated() {
            guard index == 0 else {
                print("Unexpected log entry at index \(index): \(entry.composedMessage)")
                continue
            }
            #expect(entry.composedMessage == messages[1])
        }

        logEntries = try! logStore.getEntries(
            at: logStore.position(date: logStartDate),
            matching: Logger.analyticsFilter
        )
        for (index, entry) in logEntries.enumerated() {
            guard index == 0 else {
                print("Unexpected log entry at index \(index): \(entry.composedMessage)")
                continue
            }
            #expect(entry.composedMessage == messages[2])
        }
    }

}
