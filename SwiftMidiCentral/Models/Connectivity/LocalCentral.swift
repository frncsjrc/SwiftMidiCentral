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
        communicationManager?.refresh()

        self.isScanning = true
    }

    func stopScanning() {
        isScanning = false
    }

    func connect(to peripheralId: UUID) throws {
        if let remoteIndex = communicationManager?.remotes.firstIndex(where: {
            $0.id == peripheralId
        }) {
            communicationManager?.remotes[remoteIndex].state = .connected
        } else {
            Logger.connectivity.error(
                "\(Localized.localCentralCannotConnectToPeripheral(with: peripheralId))"
            )
        }
    }

    func disconnect(from peripheralId: UUID) throws {
        if let remoteIndex = communicationManager?.remotes.firstIndex(where: {
            $0.id == peripheralId
        }) {
            communicationManager?.remotes[remoteIndex].state = .disconnected
        } else {
            Logger.connectivity.error(
                "\(Localized.localCentralCannotDisconnectFromPeripheral(with: peripheralId))"
            )
        }
    }

    func addPeripherals() {
    }
}
