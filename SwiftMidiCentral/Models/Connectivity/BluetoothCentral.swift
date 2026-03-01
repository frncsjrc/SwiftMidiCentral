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

    func connect(to peripheralId: UUID) throws {
        if let remote = communicationManager?.remotes.first(where: {
            $0.id == peripheralId
        }) {
            if case .bluetooth(let peripheral, _) = remote.interface {
                if let peripheral, peripheral.state != .connected {
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

    func disconnect(from peripheralId: UUID) throws {
        if let remote = communicationManager?.remotes.first(where: {
            $0.id == peripheralId
        }) {
            if case .bluetooth(let peripheral, _) = remote.interface {
                if let peripheral, peripheral.state == .connected {
                    centralManager.cancelPeripheralConnection(peripheral)
                }
            }
        }
    }

    func send(_ data: [Data], to remote: RemoteDetails) {
        guard case .bluetooth(let peripheral, _) = remote.interface,
            let peripheral
        else {
            return
        }

        sendBuffer[peripheral, default: []].append(contentsOf: data)

        send(to: peripheral)
    }

    private func send(to destination: CBPeripheral) {
        guard sendBuffer[destination] != nil else {
            return
        }

        guard
            let service = destination.services?.first(where: {
                $0.uuid == Constants.midiServiceUUID
            })
        else {
            Logger.connectivity.error(
                "No MIDI service found on peripheral \(destination.debugDescription)"
            )
            return
        }

        guard
            let cheracteristic = service.characteristics?.first(where: {
                $0.uuid == Constants.midiCharacteristicUUID
            })
        else {
            Logger.connectivity.error(
                "No MIDI data characteristic found on peripheral \(destination.debugDescription)"
            )
            return
        }

        while let packet = sendBuffer[destination]!.popFirst()  //            && $$destination.canSendWriteWithoutResponse
        {
            destination.writeValue(
                packet,
                for: cheracteristic,
                type: .withoutResponse
            )
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
        discoveredPeripherals.insert(peripheral)
        if peripheral.state != .connected {
            centralManager.connect(
                peripheral,
                options: [
                    CBConnectPeripheralOptionEnableAutoReconnect: true
                ]
            )
        }
        let name = peripheral.name ?? Localized.remoteUnknownDevice
        let advertisedName =
            advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? Localized.remoteUnknownDevice

        DispatchQueue.main.async {
            if let remote = self.communicationManager?.remotes.first(
                where: {
                    $0.name == name
                })
            {
                if case .bluetooth(_, let central) = remote.interface {
                    remote.advertizedName = advertisedName
                    remote.interface = .bluetooth(peripheral, central)
                    remote.state = .disconnected
                }
            } else if let remote = self.communicationManager?.remotes.first(
                where: {
                    $0.id == peripheral.identifier
                })
            {
                if case .bluetooth(_, let central) = remote.interface {
                    remote.name = name
                    remote.advertizedName = advertisedName
                    remote.interface = .bluetooth(peripheral, central)
                    remote.state = .disconnected
                }
            } else {
                self.communicationManager?.remotes.append(
                    RemoteDetails(
                        id: peripheral.identifier,
                        name: name,
                        advertizedName: advertisedName,
                        interface: .bluetooth(peripheral, nil),
                        state: .disconnected
                    )
                )
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
//        if let remote = communicationManager?.remotes.first(where: {
//            $0.name == peripheral.name
//        }) {
//            print("Found remote matching discovered peripheral: \(remote.name)")
//            if case .midi(let source, let destination) = remote.interface {
//                let endpoint: MIDIEndpointRef? =
//                    source == nil ? destination : source
//                if let endpoint {
//                    var entity = MIDIEntityRef()
//                    var device = MIDIDeviceRef()
//                    if MIDIEndpointGetEntity(endpoint, &entity) == noErr {
//                        if MIDIEntityGetDevice(entity, &device) == noErr {
//                            if MIDISetupRemoveDevice(device) == noErr {
//                                Logger.connectivity.info(
//                                    "Removed device for source MIDI endpoint"
//                                )
//                            } else {
//                                Logger.connectivity.error(
//                                    "Failed to remove device for source MIDI endpoint"
//                                )
//                            }
//                        } else {
//                            Logger.connectivity.error(
//                                "Failed to get device for source MIDI endpoint"
//                            )
//                        }
//                    } else {
//                        Logger.connectivity.error(
//                            "Failed to get entity for source MIDI endpoint"
//                        )
//                    }
//                }
//            }
//        }
        peripheral.delegate = self
        peripheral.discoverServices([Constants.midiServiceUUID])

        DispatchQueue.main.async {
            if let remote = self.communicationManager?.remotes.first(where: {
                $0.id == peripheral.identifier
            }) {
                var central: CBCentral? = nil
                if case .bluetooth(_, let formerCentral) = remote.interface {
                    central = formerCentral
                }

                remote.interface = .bluetooth(peripheral, central)
                remote.state = .connected
            } else {
                self.communicationManager?.remotes.append(
                    RemoteDetails(
                        id: peripheral.identifier,
                        name: peripheral.name ?? Localized.remoteUnknownDevice,
                        interface: .bluetooth(peripheral, nil),
                        state: .connected
                    )
                )
            }
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
            if let remote = communicationManager?.remotes.first(
                where: { $0.id == peripheral.identifier })
            {
                if case .bluetooth(_, let formerCentral) = remote.interface {
                    remote.interface = .bluetooth(peripheral, formerCentral)
                    remote.state = .disconnected
                }
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
                //                peripheral.discoverDescriptors(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)

                //                MIDIBluetoothDriverActivateAllConnections()
                //                self.communicationManager?.refresh()

                if let remote = communicationManager?.remotes.first(where: {
                    $0.id == peripheral.identifier
                }) {
                    DispatchQueue.main.async {
                        remote.state = .connected
                        remote.enableReception = true
                    }
                }
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
            if let remote = communicationManager?.remotes.first(where: {
                $0.id == peripheral.identifier
            }) {
                DispatchQueue.main.async {
                    self.communicationManager?.lastSource = remote.name
                    self.communicationManager?.lastMessages =
                        MidiMessage.decode(data)
                }
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

    func peripheralIsReady(toSendWriteRequests peripheral: CBPeripheral) {
        print("peripheral is ready to send write requests")
        send(to: peripheral)
    }

}  // CBPeripheralDelegate extension
