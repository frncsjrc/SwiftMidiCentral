//
//  BluetoothCentral.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 21/11/2025.
//

import Collections
import CoreBluetooth
import CoreMIDI
import Foundation
import OSLog

@Observable
class BluetoothCentral: NSObject, Central {

    private var centralManager: CBCentralManager!
    private var sendBuffer: [CBPeripheral: Deque<Data>] = [:]
    private(set) var isScanning: Bool = false

    var communicationManager: CommunicationManager?

    private var discoveredPeripherals: Set<CBPeripheral> = []

    override init() {
        super.init()

        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }

    func startScanning() {
        guard bluetoothIsAvailable() else {
            isScanning = false
            return
        }

        centralManager.scanForPeripherals(withServices: [
            Constants.midiServiceUUID
        ])
        isScanning = true
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }

    private func bluetoothIsAvailable() -> Bool {
        if centralManager.state == .poweredOn {
            return true
        } else {
            Logger.connectivity.warning("\(Localized.bluetoothUnavailable)")
            return false
        }
    }
}

extension BluetoothCentral: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            Logger.connectivity.info("\(Localized.bluetoothPoweredOn)")
        case .poweredOff:
            Logger.connectivity.info("\(Localized.bluetoothPoweredOff)")
        case .unauthorized:
            Logger.connectivity.warning("\(Localized.bluetoothIsNotAuthorized)")
        default:
            break
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        discoveredPeripherals.insert(peripheral)
        if peripheral.state != .connected {
            centralManager.connect(
                peripheral,
                options: [
                    CBConnectPeripheralOptionEnableAutoReconnect: true
                ]
            )
        }

    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        peripheral.delegate = self
        peripheral.discoverServices([Constants.midiServiceUUID])
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        let peripheralName = peripheral.name ?? Localized.remoteUnknownDevice
        let errorDescription =
            error?.localizedDescription ?? Localized.bluetoothUnknownError

        Logger.connectivity.warning(
            "\(Localized.bluetoothFailedToConnectToPeripheral(peripheralName, with: errorDescription))"
        )
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    ) {
        let peripheralName = peripheral.name ?? Localized.remoteUnknownDevice

        // disconnect not being a result of cancelPeripheralConnection
        if let error {
            let errorDescription = error.localizedDescription
            Logger.connectivity.warning(
                "\(Localized.bluetoothGotDisconnectedFromPeripheral(peripheralName, with: errorDescription))"
            )

            // force reconnecting if not already in progress
            if !isReconnecting {
                centralManager.connect(
                    peripheral,
                    options: [
                        CBConnectPeripheralOptionEnableAutoReconnect: true
                    ]
                )
            }
        }
    }
}

extension BluetoothCentral: CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: (any Error)?
    ) {
        if let error {
            Logger.connectivity.error(
                "Discovered services with error: \(error.localizedDescription)"
            )
            return
        }
        for service in peripheral.services ?? [] {
            if service.uuid == Constants.midiServiceUUID {
                peripheral.discoverCharacteristics(
                    [Constants.midiCharacteristicUUID],
                    for: service
                )
                break
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didModifyServices invalidatedServices: [CBService]
    ) {
        print("didModifyServices: ", invalidatedServices)
        peripheral.discoverServices(invalidatedServices.map({ $0.uuid }))
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: (any Error)?
    ) {
        if let error {
            Logger.connectivity.error(
                "Discovered included services with error: \(error.localizedDescription)"
            )
            return
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)?
    ) {
        if let error {
            Logger.connectivity.error(
                "Discovered characteristics with error: \(error.localizedDescription)"
            )
            return
        }

        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == Constants.midiCharacteristicUUID {

                peripheral.readValue(for: characteristic)
                peripheral.discoverDescriptors(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
                break
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        if let error {
            Logger.connectivity.error(
                "Discover descriptors with error: \(error.localizedDescription)"
            )
            return
        }
    }

}  // CBPeripheralDelegate extension
