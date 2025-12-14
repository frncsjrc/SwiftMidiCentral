//
//  Constants.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 21/11/2025.
//

import Foundation
import CoreBluetooth

struct Constants {
    static let rootIdentifier = Bundle.main.bundleIdentifier ?? "FrncsJRC.SwiftMidiCentral"
    
    // MIDI BLE Standard UUIDs (defined by MIDI Manufacturers Association)
    static let midiServiceUUID = CBUUID(
        string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700"
    )
    static let midiCharacteristicUUID = CBUUID(
        string: "7772E5DB-3868-4112-A1A9-F2669D106BF3"
    )
}
