//
//  RemoteDetails.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 15/08/2025.
//

import CoreBluetooth
import CoreMIDI
import Foundation

struct RemoteDetails: Identifiable {
    var id: UUID
    var name: String
    var advertisedName: String? = nil
    var peripheral: CBPeripheral? = nil
    var source: MIDIEndpointRef? = nil
    var destination: MIDIEndpointRef? = nil
    var enableReception: Bool = false
    var state: RemoteState = .offline
    var manufacturer: String? = nil
    var model: String? = nil

    init(
        id: UUID = UUID(),
        name: String,
        advertisedName: String? = nil,
        peripheral: CBPeripheral? = nil,
        source: MIDIEndpointRef? = nil,
        destination: MIDIEndpointRef? = nil,
        enableReception: Bool = false,
        state: RemoteState = .offline,
        manufacturer: String? = nil,
        model: String? = nil
    ) {
        self.id = id
        self.name = name
        self.advertisedName = advertisedName
        self.peripheral = peripheral
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
        if let advertisedName, !advertisedName.isEmpty {
            "\(name) - \(advertisedName)"
        } else {
            name
        }
    }
}
