//
//  IncomingView.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 29/11/2025.
//

import SwiftUI

struct IncomingView: View {
    @State var manager: CommunicationManager
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("Source", systemImage: "music.note.house")
                Spacer()
                Text(manager.lastSource)
            }
            .font(.headline)
            .padding(5)
            ScrollView {
                ForEach(manager.lastMessages.indices, id: \.self) { index in
                    Text(manager.lastMessages[index])
                        .fontWidth(.compressed)
                }
                .accessibilityIdentifier("receivedMessages")
            }
        }
    }
}

#Preview {
    let manager = CommunicationManager()
    manager.lastSource = "Test"
    manager.lastMessages = ["Test 1", "Test 2", "Test 3"]
    
    return IncomingView(manager: manager)
}
