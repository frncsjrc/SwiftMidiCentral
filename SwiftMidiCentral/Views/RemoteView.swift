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
    var remote: RemoteDetails
    var manager: CommunicationManager

    var body: some View {
        let enabled = remote.enableReception
        VStack(alignment: .leading) {
                Button(
                    remote.name,
                    systemImage: remote.interface.icon
                ) {
                    if enabled {
                        try? manager.disconnect(from: remote)
                    } else {
                        try? manager.connect(to: remote)
                    }
                }
                .font(.headline)
                .fontWeight(.bold)
                .fontWidth(.compressed)
                .foregroundColor(
                    remote.source == nil ? .red : enabled ? .green : .orange
                )
            if let source = remote.source {
                    Text("\(source)")
                        .padding(.leading, 10)
                }
            if let destination = remote.destination{
                    Text("\(destination)")
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

#Preview("Wired off-line") {
    let manager = CommunicationManager()
    manager.refresh()
    let remote = manager.remotes.first!
    return RemoteView(remote: remote, manager: manager)
}

#Preview("Wired") {
    let manager = CommunicationManager()
    manager.refresh()
    let remote = manager.remotes.last!
    return RemoteView(remote: remote, manager: manager)
}

#Preview("Central") {
    let manager = CommunicationManager()
    manager.central.startScanning()
    let remote = manager.remotes.last!
    return RemoteView(remote: remote, manager: manager)
}

#Preview("Peripheral") {
    let manager = CommunicationManager()
    manager.peripheral.startAdvertizing()
    let remote = manager.remotes.last!
    return RemoteView(remote: remote, manager: manager)
}
