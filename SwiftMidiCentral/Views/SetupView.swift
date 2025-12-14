//
//  SetupView.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 29/11/2025.
//

import SwiftUI

struct SetupView: View {
    @Binding var manager: CommunicationManager
    var body: some View {
        HStack {
            Button(
                manager.central.isScanning
                    ? Localized.setupViewStopScanning
                    : Localized.setupViewStartScanning,
                systemImage: "externaldrive.fill.badge.wifi"
            ) {
                if manager.central.isScanning {
                    manager.central.stopScanning()
                } else {
                    manager.central.startScanning()
                }
            }
            .accessibilityIdentifier(ViewTags.Buttons.scan)
            .padding(12)
            .background(manager.central.isScanning ? Color.green : Color.red)
            .foregroundColor(.white)
            .cornerRadius(50)
            .padding(.horizontal)

            Button(
                Localized.setupViewRefresh,
                systemImage: "arrow.trianglehead.2.clockwise"
            ) {
                manager.refresh()
            }
            .accessibilityIdentifier(ViewTags.Buttons.refresh)
            .padding(12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(50)
            .padding(.horizontal)
        }
        ScrollView {
            ForEach(manager.remotes.indices, id: \.self) { index in
                RemoteView(manager: manager, index: index)
            }
        }
    }
}

#Preview {
    @Previewable @State var manager = CommunicationManager()
    manager.central.startScanning()
    manager.selectedDestination = CommunicationManager.remoteSamples.first!
        .value.id

    return SetupView(manager: $manager)
}
