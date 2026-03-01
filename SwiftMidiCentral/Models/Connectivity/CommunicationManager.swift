//
//  CommunicationManager.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 29/11/2025.
//

import CoreMIDI
import Foundation
import OSLog

@Observable
class CommunicationManager {
    var remotes: [RemoteDetails] = []

    var central: Central = LocalCentral()
    var peripheral: Peripheral = LocalPeripheral()

    var selectedDestination: UUID? = nil

    var lastSource: String = ""
    var lastMessages: [String] = []

    var outputBuffer: [UUID: [UInt32]] = [:]

    init() {
        self.central.communicationManager = self
        self.peripheral.communicationManager = self
    }
    
    func reset() {
        remotes.removeAll()
    }

    func refresh() {
        for remoteSample in CommunicationManager.remoteSamples {
            if !remotes.contains(where: { $0.name == remoteSample.name }) {
                remotes.append(
                    RemoteDetails(
                        name: remoteSample.name,
                        interface: remoteSample.interface,
                        manufacturer: remoteSample.manufacturer,
                        model: remoteSample.model
                    )
                )
            }
        }
    }

    func connect(to id: UUID) throws {
        guard
            let remote = remotes.first(where: { $0.id == id })
        else {
            Logger.connectivity.debug(
                "Could not find remote with ID \(id) to connect to"
            )
            return
        }

        remote.enableReception = true
        Logger.connectivity.debug(
            "Connected to remote: \(remote.name)"
        )
    }

    func disconnect(from id: UUID) throws {
        guard
            let remote = remotes.first(where: { $0.id == id })
        else {
            Logger.connectivity.debug(
                "Could not find remote with ID \(id) to disconnect from"
            )
            return
        }

        remote.enableReception = false
        Logger.connectivity.debug(
            "Disconnected from remote: \(remote.name)"
        )
    }

    func sourceName(for endpoint: MIDIEndpointRef) -> String {
        if let name = remotes.first(where: {
            switch $0.interface {
            case .midi(let source, _):
                source == endpoint
            default:
                false
            }
        })?.name {
            return name
        } else {
            return Localized.localUnknownSourceName(endpoint)
        }
    }

    func destinationName(for peripheral: UUID) -> String {
        if let name = remotes.first(where: { $0.id == peripheral })?.name {
            return name
        } else {
            return Localized.localUnknownDestinationName(peripheral)
        }
    }

    func send(packets: [UInt32]) {
        guard let destination = selectedDestination else {
            Logger.connectivity.warning("No MIDI output selected to send to")
            return
        }
        
        if outputBuffer.keys.contains(destination) {
            outputBuffer[destination]?.append(contentsOf: packets)
        } else {
            outputBuffer[destination] = packets
        }
    }

    func receive(
        messages: [MIDIUniversalMessage],
        from id: UUID
    ) {
        DispatchQueue.main.async {
            self.lastSource =
            if let source = self.remotes.first(where: { $0.id == id }) {
                source.description
            } else {
                Localized.remoteUnknownDevice
            }
            
            self.lastMessages.removeAll(keepingCapacity: true)
            messages.forEach { message in
                let decodedMessage =
                MidiMessage.decode(message) ?? Localized.midiMessageUnknown
                self.lastMessages.append(decodedMessage)
            }
        }
    }

}

extension CommunicationManager {
    static let remoteSamples = [
        RemoteDetails(
            name: "Remote 1",
            interface: .midi(),
        ),
        RemoteDetails(
            name: "Remote 2",
            interface: .midi(source: 317, destination: 121),
        ),
        RemoteDetails(
            name: "Remote 3",
            interface: .midi(source: 794, destination: 331),
            manufacturer: "Tester",
            model: "Device"
        ),
    ]
}
