//
//  SwiftMidiCentralApp.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 21/11/2025.
//

import SwiftData
import SwiftUI

@main
struct SwiftMidiCentralApp: App {
    var manager: CommunicationManager =
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
        ? CommunicationManager() : MidiManager()

    var body: some Scene {
        WindowGroup {
            TopView(manager: manager)
//                .accessibilityIdentifier(ViewTags.Views.top)
        }
    }
}
