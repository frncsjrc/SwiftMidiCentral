//
//  RemoteDetails.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 15/08/2025.
//

import CoreBluetooth
import CoreMIDI
import Foundation

@Observable
class RemoteDetails: Identifiable {
    var name: String
    var interface: RemoteInterface
    var source: MIDIEndpointRef?
    var destination: MIDIEndpointRef?
    var enableReception: Bool = false
    var state: RemoteState = .offline
    var manufacturer: String? = nil
    var model: String? = nil

    init(
        name: String,
        interface: RemoteInterface = .wired,
        source: MIDIEndpointRef? = nil,
        destination: MIDIEndpointRef? = nil,
        enableReception: Bool = false,
        state: RemoteState = .offline,
        manufacturer: String? = nil,
        model: String? = nil
    ) {
        self.name = name
        self.interface = interface
        self.source = source
        self.destination = destination
        self.enableReception = enableReception
        self.state = state
        self.manufacturer = manufacturer
        self.model = model
    }
}

extension RemoteDetails: CustomStringConvertible {
    var description: String {
        name
    }
}
