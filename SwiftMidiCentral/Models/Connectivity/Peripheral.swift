//
//  Peripheral.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 14/12/2025.
//

import Foundation
import CoreBluetooth

protocol Peripheral {
    var peripheralName: String { get set }
    
    var communicationManager: CommunicationManager? { get set }

    var isAdvertizing: Bool { get }

    func startAdvertizing()
    func stopAdvertising()
    
    func send(_: Data, to: UUID)
}
