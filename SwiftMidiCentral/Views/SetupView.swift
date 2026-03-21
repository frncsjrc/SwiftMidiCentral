//
//  PeripheralScannerView.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 01/03/2026.
//

import CoreAudioKit
import SwiftUI

struct SetupView: View {
    @Binding var manager: CommunicationManager
    @State private var previousPeripheralName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var scanLabel: String {
        manager.central.isScanning
            ? Localized.setupViewStopScanning
            : Localized.setupViewStartScanning
    }

    var advertizeLabel: String {
        manager.peripheral.isAdvertizing
            ? Localized.setupViewStopAdvertizing
            : Localized.setupViewStartAdvertizing
    }

    var body: some View {
        VStack {
            Button(
                Localized.setupViewReset,
                systemImage: "arrow.trianglehead.2.clockwise"
            ) {
                manager.reset()
            }
            .accessibilityIdentifier(ViewTags.Buttons.reset)
            .padding()

            Button(
                Localized.setupViewRefresh,
                systemImage: "arrow.trianglehead.2.clockwise"
            ) {
                manager.refresh()
            }
            .accessibilityIdentifier(ViewTags.Buttons.refresh)
            .cornerRadius(50)
            .padding(.bottom)

            Spacer()

            TextField(
                Localized.bluetoothPeripheralName,
                text: $manager.peripheral.peripheralName
            )
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, 20)
            .onChange(of: manager.peripheral.peripheralName) { oldValue, newValue in
                if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                    manager.peripheral.peripheralName = oldValue
                } else {
                    previousPeripheralName = newValue
                }
            }
            
            Button(
                advertizeLabel,
                systemImage: "externaldrive.fill.badge.wifi"
            ) {
                if manager.peripheral.isAdvertizing {
                    manager.peripheral.stopAdvertising()
                } else {
                    manager.peripheral.startAdvertizing()
                }
            }
            .accessibilityIdentifier(ViewTags.Buttons.advertize)
            .cornerRadius(50)
            .padding(.bottom)

            Spacer()

            BluetoothCentralController()
        }
        .onAppear {
            manager.central.startScanning()
            // Initialize the previous value
            previousPeripheralName = manager.peripheral.peripheralName.isEmpty 
                ? "Default Device" 
                : manager.peripheral.peripheralName
            print("Setup button stack appears")
        }
        .onDisappear {
            manager.central.stopScanning()
        }
    }
}

struct BluetoothCentralController: UIViewControllerRepresentable {
    typealias UIViewControllerType = CABTMIDICentralViewController

    func makeUIViewController(context: Context) -> CABTMIDICentralViewController
    {
        CABTMIDICentralViewController()
    }

    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {}
}

#Preview {
    @Previewable @State var manager = CommunicationManager()
    SetupView(manager: $manager)
}
