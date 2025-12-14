//
//  BluetoothCentral.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 21/11/2025.
//

import CoreBluetooth
import CoreMIDI
import Foundation
import OSLog

@Observable
class BluetoothCentral: NSObject, Central {

    private var centralManager: CBCentralManager!
    private(set) var isScanning: Bool = false

    var communicationManager: CommunicationManager?

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

    func connect(to peripheralId: UUID) throws {
        if let peripheral = communicationManager?.remotes.first(where: {
            $0.id == peripheralId
        })?.peripheral {
            if peripheral.state != .connected {
                centralManager.connect(
                    peripheral,
                    options: [
                        CBConnectPeripheralOptionEnableAutoReconnect: true
                    ]
                )
            }
        }
    }

    func disconnect(from peripheralId: UUID) throws {
        if let peripheral = communicationManager?.remotes.first(where: {
            $0.id == peripheralId
        })?.peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func bluetoothIsAvailable() -> Bool {
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
        let name = peripheral.name ?? Localized.remoteUnknownDevice
        let advertisedName =
            advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? Localized.remoteUnknownDevice

        DispatchQueue.main.async {
            if let remoteIndex = self.communicationManager?.remotes.firstIndex(
                where: {
                    $0.id == peripheral.identifier
                })
            {
                self.communicationManager?.remotes[remoteIndex].name = name
                self.communicationManager?.remotes[remoteIndex].advertisedName =
                    advertisedName
                self.communicationManager?.remotes[remoteIndex].peripheral =
                    peripheral
                self.communicationManager?.remotes[remoteIndex].state = .offline
            } else {
                self.communicationManager?.remotes.append(
                    RemoteDetails(
                        id: peripheral.identifier,
                        name: name,
                        advertisedName: advertisedName,
                        peripheral: peripheral,
                        state: .offline
                    )
                )
            }
        }

        centralManager.connect(
            peripheral,
            options: [CBConnectPeripheralOptionEnableAutoReconnect: true]
        )
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        peripheral.delegate = self
        peripheral.discoverServices([Constants.midiServiceUUID])

        if let remoteIndex = communicationManager?.remotes.firstIndex(where: {
            $0.id == peripheral.identifier
        }) {
            communicationManager?.remotes[remoteIndex].peripheral = peripheral
        }
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
        } else {
            if let remoteIndex = communicationManager?.remotes.firstIndex(
                where: { $0.id == peripheral.identifier })
            {
                communicationManager?.remotes[remoteIndex].peripheral =
                    peripheral
            }
            Logger.connectivity.info(
                "\(Localized.bluetoothDidDisconnectFromPeripheral(peripheralName))"
            )
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
                self.communicationManager?.refresh()
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

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        if let error {
            Logger.connectivity.error(
                "Notification state updated with error: \(error.localizedDescription)"
            )
        }

    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        print("didWriteValueFor")

        if let error {
            Logger.connectivity.error(
                "Did write value with error: \(error.localizedDescription)"
            )
            return
        } else if !characteristic.isNotifying {
            print("reading value")
            peripheral.readValue(for: characteristic)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        print("didUpdateValueFor characteristic", characteristic)

        if let error {
            Logger.connectivity.error(
                "Did update characteristic value with error: \(error.localizedDescription)"
            )
            return
        }
        if let data = characteristic.value, !data.isEmpty {
            print("Updated characteristic value: \(data)")

            if let remote = communicationManager?.remotes.first(where: {
                $0.id == peripheral.identifier
            }), remote.source == nil {
                communicationManager?.lastSource = remote.name
                communicationManager?.lastMessages = MidiMessage.decode(data)
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: (any Error)?
    ) {
        print("didUpdateValueFor descriptor", descriptor)
        if let error {
            Logger.connectivity.error(
                "Did update descriptor value with error: \(error.localizedDescription)"
            )
            return
        }
        if let data = descriptor.value {
            print("Updated descriptor value: \(data)")
        }
    }

}  // CBPeripheralDelegate extension
