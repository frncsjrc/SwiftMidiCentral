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

    var selectedDestination: MIDIEndpointRef? = nil

    var lastSource: String = ""
    var lastMessages: [String] = []

    var outputBuffer: [MIDIEndpointRef: [UInt32]] = [:]

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
                        source: remoteSample.source,
                        destination: remoteSample.destination,
                        manufacturer: remoteSample.manufacturer,
                        model: remoteSample.model
                    )
                )
            }
        }
    }

    func connect(to remote: RemoteDetails) throws {
        remote.enableReception = true
        Logger.connectivity.debug(
            "Connected to remote: \(remote.name)"
        )
    }

    func disconnect(from remote: RemoteDetails) throws {
        remote.enableReception = false
        Logger.connectivity.debug(
            "Disconnected from remote: \(remote.name)"
        )
    }

    func sourceName(for endpoint: MIDIEndpointRef) -> String {
        if let name = remotes.first(where: {
            $0.source == endpoint
        })?.name {
            return name
        } else {
            return Localized.localUnknownSourceName(endpoint)
        }
    }

    func destinationName(for endpoint: MIDIEndpointRef) -> String {
        if let name = remotes.first(where: {
            $0.destination == endpoint
        })?.name {
            return name
        } else {
            return Localized.localUnknownDestinationName(endpoint)
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
        from name: String
    ) {
//        DispatchQueue.main.async {
            self.lastSource =
            if let source = self.remotes.first(where: { $0.name == name }) {
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
//        }
    }

}

extension CommunicationManager {
    static let remoteSamples = [
        RemoteDetails(
            name: "Remote 1",
            interface: .wired,
        ),
        RemoteDetails(
            name: "Remote 2",
            interface: .wired,
            source: 317,
            destination: 121,
        ),
        RemoteDetails(
            name: "Remote 3",
            interface: .wired,
            source: 794,
            destination: 331,
            manufacturer: "Tester",
            model: "Device"
        ),
    ]
}
