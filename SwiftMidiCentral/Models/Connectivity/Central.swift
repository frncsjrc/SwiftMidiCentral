//
//  Central.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 21/11/2025.
//

import Foundation

protocol Central {
    var communicationManager: CommunicationManager? { get set }
    
    var isScanning: Bool { get }
    
    func startScanning()
    func stopScanning()
    
    func connect(to device: UUID) throws
    func disconnect(from device: UUID) throws
}
