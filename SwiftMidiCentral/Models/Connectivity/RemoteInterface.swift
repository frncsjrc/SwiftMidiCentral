//
//  RemoteInterface.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 04/01/2026.
//

import CoreBluetooth
import CoreMIDI
import Foundation

enum RemoteInterface: Equatable {
    case midi(source: MIDIEndpointRef? = nil, destination: MIDIEndpointRef? = nil)
    case bluetooth(CBPeripheral? = nil, CBCentral? = nil)
}
