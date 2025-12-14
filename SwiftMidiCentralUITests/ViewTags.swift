//
//  ViewIdentifiers.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 13/12/2025.
//

import Foundation

struct ViewTags {
    struct Views {
        static let top: String = "TopView"
        static let setup: String = "SetupView"
        static let outgoing: String = "OutgoingView"
        static let incoming: String = "IncomingView"
        static let remote: String = "RemoteView"
    }
    
    struct Pickers {
        static let destination: String = "destinationPicker"
    }
    
    struct Buttons {
        static let scan: String = "scanButton"
        static let refresh: String = "refreshButton"
        static let c4: String = "c4Button"
        static let e4: String = "e4Button"
        static let cc: String = "ccButton"
        static let pc: String = "pcButton"
        static let bkpc: String = "bkpcButton"
    }
}
