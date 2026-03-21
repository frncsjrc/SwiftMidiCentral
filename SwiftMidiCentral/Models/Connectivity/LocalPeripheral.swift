//
//  LocalPeripheral.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 30/12/2025.
//

import Foundation
import OSLog

@Observable
class LocalPeripheral: Peripheral {
    var peripheralName: String = "Local Peripheral"

    private(set) var isAdvertizing: Bool = false

    var communicationManager: CommunicationManager?

    func startAdvertizing() {
        print("Starting advertising as \(peripheralName)...")
        addRemotes()
        isAdvertizing = true
    }

    func stopAdvertising() {
        isAdvertizing = false
    }

    private func addRemotes() {
        guard let communicationManager else {
            return
        }

        for sample in LocalPeripheral.remoteSamples {
            if !communicationManager.remotes.contains(where: {
                $0.name == sample.name
            }) {
                communicationManager.remotes.append(sample)
            }
            print("Adding remote: \(sample.name)")
        }
    }
}

extension LocalPeripheral {
    static let remoteSamples = [
        RemoteDetails(
            name: "Central 1",
            interface: .bluetooth,
            source: nil,
            destination: 6_652_331,
            state: .connected
        ),
        RemoteDetails(
            name: "Central 2",
            interface: .bluetooth,
            source: 5_534_221,
            destination: nil,
        ),
        RemoteDetails(
            name: "Central 3",
            interface: .bluetooth,
            source: 2_143_657,
            destination: 3_987_654,
            state: .connected,
            manufacturer: "Tester",
            model: "Device"
        ),
    ]
}
