//
//  SetupView.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 29/11/2025.
//

import SwiftUI

struct SetupView: View {
    @State var manager: CommunicationManager

    var body: some View {
        HStack {
            Button(
                Localized.setupViewStartScanning,
                systemImage: "externaldrive.fill.badge.wifi"
            ) {
                if manager.central.isScanning {
                    manager.central.stopScanning()
                } else {
                    manager.central.startScanning()
                }
            }
            .accessibilityIdentifier(ViewTags.Buttons.scan)
            .strikethrough(!manager.central.isScanning)
            .fontWidth(.compressed)
            .padding(8)
            .background(manager.central.isScanning ? Color.green : Color.red)
            .foregroundColor(.white)
            .cornerRadius(50)

            Button(
                Localized.setupViewStartAdvertizing,
                systemImage: "externaldrive.fill.badge.wifi"
            ) {
                if manager.peripheral.isAdvertizing {
                    manager.peripheral.stopAdvertising()
                } else {
                    manager.peripheral.startAdvertizing()
                }
            }
            .accessibilityIdentifier(ViewTags.Buttons.advertize)
            .strikethrough(!manager.peripheral.isAdvertizing)
            .fontWidth(.compressed)
            .padding(8)
            .background(
                manager.peripheral.isAdvertizing ? Color.green : Color.red
            )
            .foregroundColor(.white)
            .cornerRadius(50)

            Button(
                Localized.setupViewRefresh,
                systemImage: "arrow.trianglehead.2.clockwise"
            ) {
                manager.refresh()
            }
            .accessibilityIdentifier(ViewTags.Buttons.refresh)
            .fontWidth(.compressed)
            .padding(8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(50)
        }
        .onAppear {
            print("Setup button stack appears")
        }

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(manager.remotes.indices, id: \.self) { index in
                    RemoteView(
                        remote: $manager.remotes[index],
                        manager: manager
                    )
                }
            }
        }
        .onAppear {
            print("Setup scroll view appears")
        }
    }
}

#Preview {
    @Previewable @State var manager = CommunicationManager()
    return SetupView(manager: manager)
}
