//
//  TopView.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 29/11/2025.
//

import SwiftUI

struct TopView: View {
    @State var manager: CommunicationManager

    var body: some View {
        VStack(alignment: .leading) {
            Section(
                header:
                    Text("Setup")
                    .font(.title)
                    .fontWeight(.bold)
            ) {
                SetupView(manager: manager)
            }
            .padding(.horizontal, 10)

            Section(
                header:
                    Text("Send")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)
            ) {
                OutgoingView(
                    manager: $manager
                )
                .onAppear {
                    print("Outgoing view appears")
                }
            }
            .padding(.horizontal, 10)

            Section(
                header:
                    Text("Receive")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)
            ) {
                IncomingView(manager: manager)
                    .onAppear {
                        print("Incoming view appears")
                    }
            }
            .padding(.horizontal, 10)
        }
        .onAppear {
            print("Top view appears")
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}

#Preview {
    let manager = CommunicationManager()
    manager.lastSource = "Test"
    manager.lastMessages = ["Test 1", "Test 2", "Test 3"]

    return TopView(manager: manager)
}
