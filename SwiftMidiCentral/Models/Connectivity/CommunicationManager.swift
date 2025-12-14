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

    var selectedDestination: UUID? = nil

    var lastSource: String = ""
    var lastMessages: [String] = []

    var outputBuffer: [UUID: [UInt32]] = [:]

    init() {
        self.central.communicationManager = self
    }

    func refresh() {
        for (key, value) in CommunicationManager.remoteSamples {
            if let identifier = UUID(uuidString: key) {
                if let remoteIndex = remotes.firstIndex(
                    where: { $0.id == identifier })
                {
                    remotes[remoteIndex].name =
                        value.name
                    remotes[remoteIndex].source =
                        value.source
                    remotes[remoteIndex].destination =
                        value.destination
                    remotes[remoteIndex].manufacturer =
                        value.manufacturer
                    remotes[remoteIndex].model =
                        value.model
                } else {
                    remotes.append(
                        RemoteDetails(
                            id: identifier,
                            name: value.name,
                            source: value.source,
                            destination: value.destination,
                            manufacturer: value.manufacturer,
                            model: value.model
                        )
                    )
                }
            }
        }
    }

    func connect(to peripheral: MIDIEndpointRef) {
        if let remoteIndex = self.remotes.firstIndex(where: {
            $0.source == peripheral
        }) {
            self.remotes[remoteIndex].enableReception = true
            if self.remotes[remoteIndex].state != .connected {
                try? central.connect(to: self.remotes[remoteIndex].id)
            }
        }
    }

    func disconnect(from peripheral: MIDIEndpointRef) {
        if let remoteIndex = self.remotes.firstIndex(where: {
            $0.source == peripheral
        }) {
            self.remotes[remoteIndex].enableReception = false
        }
    }
    
    func sourceName(for peripheral: MIDIEndpointRef) -> String {
        if let name = remotes.first(where: { $0.source == peripheral })?.name {
            return name
        } else {
            return Localized.localUnknownSourceName(peripheral)
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
        guard let destination = self.selectedDestination else {
            Logger.connectivity.error("\(Localized.localUnsetDestination)")
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
        from peripheral: MIDIEndpointRef
    ) {
        self.lastSource =
            if let source = remotes.first(where: {
                $0.source == peripheral
            }) {
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

extension CommunicationManager {
    static let remoteSamples = [
        "3461256A-35A3-F393-E0A9-BA9456DCCA9E": RemoteDetails(
            name: "Remote 1",
            source: 125,
            destination: 126
        ),
        "D6A8256A-35A3-F393-E0A9-E50E24DCCA9E": RemoteDetails(
            name: "Remote 2",
            source: 317,
            destination: 429,
        ),
        "47C8256A-35A3-F393-E0A9-BC8E24DCCA9E": RemoteDetails(
            name: "Remote 3",
            source: 794,
            destination: 331,
            manufacturer: "Tester",
            model: "Device"
        ),
    ]
}
