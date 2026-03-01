//
//  OutgoingView.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 29/11/2025.
//

import CoreBluetooth
import CoreMIDI
import SwiftUI

struct OutgoingView: View {
    @Binding var manager: CommunicationManager

    @State var selectedDestination: UUID? = nil

    var destinationIndices: Set<Int> {
        var indices: Set<Int> = []
        for (index, remote) in manager.remotes.enumerated() {
            let connected =
                switch remote.interface {
                case .midi(_, let destination):
                    destination != nil
                case .bluetooth:
                    remote.state == .connected
                }
            if connected {
                if manager.selectedDestination == nil {
                    manager.selectedDestination = remote.id
                }
                indices.insert(index)
            }
        }
        return indices
    }

    var body: some View {
        VStack(alignment: .leading) {
            if destinationIndices.isEmpty {
                Text(Localized.outgoingViewNoDestinations)
            } else {
                HStack {
                    Text(Localized.outgoingViewDestinationLabel)
                    Spacer()
                    Picker(
                        Localized.outgoingViewDestinationLabel,
                        selection: $selectedDestination
                    ) {
                        ForEach(manager.remotes) { remote in
                            let disconnected = remote.state != .connected
                            Text(remote.name).tag(remote.id)
                                .selectionDisabled(disconnected)
                        }
                    }
                    .onChange(of: selectedDestination) {
                        manager.selectedDestination = selectedDestination
                    }
                }
                .padding(.horizontal)
            }
            VStack {
                HStack {
                    Spacer()
                    Button("C4", systemImage: "music.note") {
                        manager.send(packets: OutgoingView.c4Note)
                    }
                    .accessibilityIdentifier(ViewTags.Buttons.c4)
                    Button("E4", systemImage: "music.note") {
                        manager.send(packets: OutgoingView.e4Note)
                    }
                    .accessibilityIdentifier(ViewTags.Buttons.e4)
                    Button(
                        "CC",
                        systemImage: "gauge.with.dots.needle.33percent"
                    ) {
                        manager.send(packets: OutgoingView.cc12)
                    }
                    .accessibilityIdentifier(ViewTags.Buttons.cc)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button("PC", systemImage: "book.fill") {
                        manager.send(packets: OutgoingView.pc51)
                    }
                    .accessibilityIdentifier(ViewTags.Buttons.pc)
                    Button("BK PC", systemImage: "books.vertical.fill") {
                        manager.send(packets: OutgoingView.bankPc51)
                    }
                    .accessibilityIdentifier(ViewTags.Buttons.bkpc)
                    Spacer()
                }
            }
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .disabled(selectedDestination == nil)
        }
        .onChange(of: destinationIndices) {
            if selectedDestination == nil {
                if manager.selectedDestination != nil {
                    selectedDestination = manager.selectedDestination
                } else if !destinationIndices.isEmpty {
                    selectedDestination =
                        manager.remotes[destinationIndices.first!].id
                }
            }
        }
    }
}

extension OutgoingView {
    static let c4Note: [UInt32] = [
        MIDI1UPNoteOn(0, 0, 60, 127),
        MIDI1UPNoteOff(0, 0, 60, 127),
    ]

    static let e4Note: [UInt32] = [
        MIDI1UPNoteOn(0, 0, 64, 127),
        MIDI1UPNoteOff(0, 0, 64, 0),
    ]

    static let cc12: [UInt32] = [
        MIDI1UPControlChange(0, 0, 12, 73)
    ]

    static let pc51: [UInt32] = [
        MIDI1UPProgramChange(0, 0, 51)
    ]

    static let bankPc51: [UInt32] = [
        MIDI1UPControlChange(0, 0, 0, 1),
        MIDI1UPControlChange(0, 0, 32, 2),
        MIDI1UPProgramChange(0, 0, 17),
    ]
}

#Preview("Wired") {
    @Previewable @State var manager = CommunicationManager()
    manager.refresh()
    return OutgoingView(manager: $manager)
}

#Preview("Central") {
    @Previewable @State var manager = CommunicationManager()
    manager.central.startScanning()
    return OutgoingView(manager: $manager)
}

#Preview("Peripheral") {
    @Previewable @State var manager = CommunicationManager()
    manager.peripheral.startAdvertizing()
    return OutgoingView(manager: $manager)
}

#Preview("Disconnected") {
    @Previewable @State var manager = CommunicationManager()

    manager.remotes.append(contentsOf: [
        RemoteDetails(name: "Test1", state: .disconnected),
        RemoteDetails(name: "Test2", state: .offline),
    ])

    return OutgoingView(manager: $manager)
}

#Preview("Empty") {
    @Previewable @State var manager = CommunicationManager()
    OutgoingView(manager: $manager)
}
