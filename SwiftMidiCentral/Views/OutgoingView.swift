//
//  OutgoingView.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 29/11/2025.
//

import CoreMIDI
import SwiftUI
import CoreBluetooth

struct OutgoingView: View {
    @Binding var manager: CommunicationManager

    var remotes: [UUID: String] {
        var remotes: [UUID: String] = [:]
        manager.remotes.forEach { remote in
            if remote.peripheral?.state == .connected || remote.destination != nil {
                remotes[remote.id] = remote.name
            }
        }
        if remotes.isEmpty {
            manager.selectedDestination = nil
        } else if manager.selectedDestination == nil
            || !remotes.keys.contains(manager.selectedDestination!)
        {
            manager.selectedDestination = remotes.first?.key
        }
        return remotes
    }

    var body: some View {
        VStack(alignment: .leading) {
            if remotes.isEmpty {
                Text(Localized.outgoingViewNoDestinations)
            } else {
                HStack {
                    Text(Localized.outgoingViewDestinationLabel)
                    Spacer()
                    Picker(
                        Localized.outgoingViewDestinationLabel,
                        selection: $manager.selectedDestination
                    ) {
                        ForEach($manager.remotes) { $remote in
                            Text(remote.name)
                                .tag(remote.id)
                        }
                    }
//                    .accessibilityIdentifier(ViewTags.Pickers.destination)
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
            .disabled(manager.selectedDestination == nil)
        }
    }
}

extension OutgoingView {
    static let c4Note: [UInt32] = [
        MIDI1UPNoteOn(0, 0, 60, 128),
        MIDI1UPNoteOff(0, 0, 60, 0),
    ]

    static let e4Note: [UInt32] = [
        MIDI1UPNoteOn(0, 0, 64, 128),
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

#Preview {
    @Previewable @State var manager = CommunicationManager()
    manager.central.startScanning()
    manager.selectedDestination =
        CommunicationManager.remoteSamples.first!.value.id

    return OutgoingView(manager: $manager)
}
