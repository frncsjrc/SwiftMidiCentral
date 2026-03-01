//
//  RemoteView.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 30/11/2025.
//

import CoreBluetooth
import CoreMIDI
import SwiftUI

struct RemoteView: View {
    @Binding var remote: RemoteDetails

    var manager: CommunicationManager

    var body: some View {
        let enabled = remote.enableReception
        VStack(alignment: .leading) {
            switch remote.interface {
            case .midi(let source, let destination):
                Button(
                    remote.name,
                    systemImage: "externaldrive.connected.to.line.below"
                ) {
                    if enabled {
                        try? manager.disconnect(from: remote.id)
                    } else {
                        try? manager.connect(to: remote.id)
                    }
                }
                .font(.headline)
                .fontWeight(.bold)
                .fontWidth(.compressed)
                .foregroundColor(
                    source == nil ? .red : enabled ? .green : .orange
                )
                if let source {
                    Text("\(source)")
                        .padding(.leading, 10)
                }
                if let destination {
                    Text("\(destination)")
                        .padding(.leading, 10)
                }
            case .bluetooth(let peripheral, let central):
                if peripheral != nil {
                    Button(remote.name, systemImage: "externaldrive.badge.wifi") {
                        if remote.state != .connected {
                            try? manager.central.connect(to: remote.id)
                        } else {
                            try? manager.central.disconnect(from: remote.id)
                        }
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(peripheralButtonColor(for: remote))
                } else if central != nil {
                    if remote.state == .connected {
                        Button(remote.name, systemImage: "externaldrive.badge.wifi") {
                            remote.enableReception.toggle()
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .fontWidth(.compressed)
                        .foregroundColor(enabled ? .green : .orange)
                    } else {
                        Text(remote.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .fontWidth(.compressed)
                            .foregroundColor(.red)
                    }
                } else {
                    Label(remote.name, systemImage: "externaldrive.badge.wifi")
                        .font(.headline)
                        .italic(true)
                        .fontWidth(.compressed)
                        .foregroundColor(.red)
                }
                Text("\(remote.id)")
                    .fontWidth(.compressed)
                    .padding(.leading, 10)
            }
        }
        .fixedSize()
        .padding(.horizontal)
        .padding(.bottom, 10)
        .onAppear {
            print("Remote view \(remote.name) appears")
        }
    }

    func peripheralButtonColor(for remote: RemoteDetails) -> Color {
        switch remote.state {
        case .disconnected:
            return .red
        case .connected:
            return remote.enableReception ? .green : .orange
        default:
            return .gray
        }
    }
}

#Preview("Wired") {
    @Previewable @State var remote = RemoteDetails(
        name: "",
        interface: .midi()
    )
    let manager = CommunicationManager()
    manager.refresh()
    remote.name = manager.remotes.last!.name
    remote.interface = manager.remotes.last!.interface
    return RemoteView(remote: $remote, manager: manager)
}

#Preview("Central") {
    @Previewable @State var remote = RemoteDetails(
        name: "",
        interface: .midi()
    )
    let manager = CommunicationManager()
    manager.central.startScanning()
    remote.name = manager.remotes.last!.name
    remote.interface = manager.remotes.last!.interface
    return RemoteView(remote: $remote, manager: manager)
}

#Preview("Peripheral") {
    @Previewable @State var remote = RemoteDetails(
        name: "",
        interface: .midi()
    )
    let manager = CommunicationManager()
    manager.peripheral.startAdvertizing()
    remote.name = manager.remotes.last!.name
    remote.interface = manager.remotes.last!.interface
    return RemoteView(remote: $remote, manager: manager)
}
