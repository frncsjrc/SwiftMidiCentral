//
//  RemoteView.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 30/11/2025.
//

import CoreBluetooth
import SwiftUI

struct RemoteView: View {
    var manager: CommunicationManager
    var index: Int

    var body: some View {
        let remote = manager.remotes[index]
        VStack(alignment: .leading) {
            if let peripheral = remote.peripheral {
                let state = peripheral.state
                Button(remote.name, systemImage: "wifi") {
                    if state == .disconnected {
                        try? manager.central.connect(to: remote.id)
                    } else {
                        try? manager.central.disconnect(from: remote.id)
                    }
                }
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(buttonColor(for: state))
            } else {
                Text(remote.name)
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text("\(remote.id)")
                .fontWidth(.compressed)

            if let source = remote.source {
                Text("\(source)")
            } else {
                Text(Localized.setupViewUnknownSource)
            }

            if let destination = remote.destination {
                Text("\(destination)")
            } else {
                Text(Localized.setupViewUnknownDestination)
            }
        }
        .fixedSize()
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    func buttonColor(for state: CBPeripheralState) -> Color {
        switch state {
        case .disconnected:
            return .red
        case .connecting:
            return .yellow
        case .connected:
            return .green
        case .disconnecting:
            return .orange
        default:
            return .gray
        }
    }
}

#Preview {
    let manager = CommunicationManager()
    manager.central.startScanning()

    return RemoteView(manager: manager, index: 0)
}
