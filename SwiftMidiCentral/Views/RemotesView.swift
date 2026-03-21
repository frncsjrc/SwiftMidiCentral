//
//  RemotesView.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 29/11/2025.
//

import SwiftUI

struct RemotesView: View {
    @State var manager: CommunicationManager

    @State private var presenSetup = false

    var body: some View {
        Button(action: {
            presenSetup = true
        }) {
            Label(
                Localized.remotesCommunicaationSetup,
                systemImage: "network"
            )
        }
        .padding()
        .sheet(isPresented: $presenSetup) {
            NavigationStack {
                SetupView(manager: $manager)
            }
        }

        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(manager.remotes.indices, id: \.self) { index in
                    RemoteView(
                        remote: manager.remotes[index],
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
    return RemotesView(manager: manager)
}
