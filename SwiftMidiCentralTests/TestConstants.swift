//
//  TestConstants.swift
//  SwiftMidiCentralTests
//
//  Created by François Jean Raymond CLÉMENT on 22/11/2025.
//

import CoreBluetooth
import Foundation
import Testing

@testable import SwiftMidiCentral

@Suite("Constants Tests")
struct TestConstants {

    @Test("Root identifier is not empty")
    func rootIdentifierIsNotEmpty() {
        #expect(!Constants.rootIdentifier.isEmpty)
    }

    @Test("Root identifier has valid format")
    func rootIdentifierHasValidFormat() {
        // Bundle identifiers should contain at least one dot (reverse DNS format)
        // or be the fallback value
        let hasDot = Constants.rootIdentifier.contains(".")
        let isFallback = Constants.rootIdentifier == "FrncsJRC.SwiftMidiCentral"

        #expect(
            hasDot || isFallback,
            "Root identifier should be in reverse DNS format or fallback value"
        )
    }

    @Test("MIDI Service UUID matches BLE MIDI specification")
    func midiServiceUUIDMatchesSpec() {
        // The MIDI Service UUID is defined by the MIDI Manufacturers Association
        // as part of the BLE MIDI specification
        let expectedUUIDString = "03B80E5A-EDE8-4B33-A751-6CE34EC4C700"
        let expectedUUID = CBUUID(string: expectedUUIDString)

        #expect(Constants.midiServiceUUID == expectedUUID)
    }

    @Test("MIDI Characteristic UUID matches BLE MIDI specification")
    func midiCharacteristicUUIDMatchesSpec() {
        // The MIDI I/O Characteristic UUID is defined by the MIDI Manufacturers Association
        // as part of the BLE MIDI specification
        let expectedUUIDString = "7772E5DB-3868-4112-A1A9-F2669D106BF3"
        let expectedUUID = CBUUID(string: expectedUUIDString)

        #expect(Constants.midiCharacteristicUUID == expectedUUID)
    }
}
