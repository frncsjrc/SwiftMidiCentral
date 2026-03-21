//
//  RemoteInterface.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 04/01/2026.
//

import CoreBluetooth
import CoreMIDI
import Foundation

enum RemoteInterface: Equatable {
    case wired
    case bluetooth
    
    var icon: String {
        switch self {
        case .wired:
            return "externaldrive.connected.to.line.below"
        case .bluetooth:
            return "externaldrive.badge.wifi"
        }
    }
}
