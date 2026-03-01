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
        addRemotes()
        isAdvertizing = true
    }

    func stopAdvertising() {
        isAdvertizing = false
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

    func send(_ data: Data, to centralId: UUID) {
        Logger.connectivity.debug(
            "Sending data \(data) to central with id \(centralId)"
        )
    }

    private func addRemotes() {
        guard let communicationManager else {
            return
        }

        for (key, value) in LocalPeripheral.remoteSamples {
            if let identifier = UUID(uuidString: key) {
                if !communicationManager.remotes.contains(where: {
                    $0.id == identifier
                }) {
                    communicationManager.remotes.append(
                        RemoteDetails(
                            id: identifier,
                            name: value.name,
                            interface: .bluetooth()
                        )
                    )
                }
                print("Adding remote: \(identifier)")
                if let remote =
                    communicationManager.remotes.first(where: {
                        $0.id == identifier
                    })
                {
                    remote.name = value.name
                    remote.state = value.state
                    remote.manufacturer = value.manufacturer
                    remote.model = value.model
                }
                if let index =
                    communicationManager.remotes.firstIndex(where: {
                        $0.id == identifier
                    })
                {
//                    communicationManager.remotes[index].name = value.name
//                    communicationManager.remotes[index].state = value.state
//                    communicationManager.remotes[index].manufacturer = value.manufacturer
//                    communicationManager.remotes[index].model = value.model
                    print("Updated remote name: \(communicationManager.remotes[index].name)")
                }
            }
        }
    }
}

extension LocalPeripheral {
    static let remoteSamples = [
        "3461256A-35A3-F393-E0A9-BA9456DCCA9E": RemoteDetails(
            name: "Central 1",
            state: .connected
        ),
        "D6A8256A-35A3-F393-E0A9-E50E24DCCA9E": RemoteDetails(
            name: "Central 2",
        ),
        "47C8256A-35A3-F393-E0A9-BC8E24DCCA9E": RemoteDetails(
            name: "Central 3",
            state: .connected,
            manufacturer: "Tester",
            model: "Device"
        ),
    ]
}
