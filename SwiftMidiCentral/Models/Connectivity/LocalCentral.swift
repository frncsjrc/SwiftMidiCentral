//
//  LocalCentral.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 21/11/2025.
//

import Foundation
import OSLog

@Observable
class LocalCentral: Central {

    private(set) var isScanning: Bool = false

    var communicationManager: CommunicationManager?

    func startScanning() {
        self.addRemotes()
        self.isScanning = true
    }

    func stopScanning() {
        self.isScanning = false
    }

    private func addRemotes() {
        guard let communicationManager else {
            return
        }

        for sample in LocalCentral.remoteSamples {
            if !communicationManager.remotes.contains(where: {
                $0.name == sample.name
            }) {
                communicationManager.remotes.append(sample)
            }
        }
    }
}

extension LocalCentral {
    static let remoteSamples = [
        RemoteDetails(
            name: "Peripheral 1",
            interface: .bluetooth,
            source: 1267,
            destination: nil
        ),
        RemoteDetails(
            name: "Peripheral 2",
            interface: .bluetooth,
            source: nil,
            destination: 56224,
            state: .connected
        ),
        RemoteDetails(
            name: "Peripheral 3",
            interface: .bluetooth,
            source: 98352,
            destination: 345,
            state: .connected,
            manufacturer: "Tester",
            model: "Device"
        ),
    ]
}
