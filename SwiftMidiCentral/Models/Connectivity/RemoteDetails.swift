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
    var id: UUID
    var interface: RemoteInterface
    var name: String
    var advertizedName: String? = nil
    var enableReception: Bool = false
    var state: RemoteState = .offline
    var manufacturer: String? = nil
    var model: String? = nil

    init(
        id: UUID = UUID(),
        name: String,
        advertizedName: String? = nil,
        interface: RemoteInterface = .midi(),
        enableReception: Bool = false,
        state: RemoteState = .offline,
        manufacturer: String? = nil,
        model: String? = nil
    ) {
        self.id = id
        self.name = name
        self.advertizedName = advertizedName
        self.interface = interface
        self.enableReception = enableReception
        self.state = state
        self.manufacturer = manufacturer
        self.model = model
    }
}

extension RemoteDetails: CustomStringConvertible {
    var description: String {
        if let advertizedName, !advertizedName.isEmpty {
            "\(name) - \(advertizedName)"
        } else {
            name
        }
    }
}
