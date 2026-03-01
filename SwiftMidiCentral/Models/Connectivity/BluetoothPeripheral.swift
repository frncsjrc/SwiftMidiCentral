//
//  BluetoothPeripheral.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 14/12/2025.
//

import CoreBluetooth
import CoreMIDI
import Foundation
import OSLog

@Observable
class BluetoothPeripheral: NSObject, Peripheral {
    var peripheralName: String = "SwiftMidiPeripheral"

    private(set) var isAdvertizing: Bool = false

    var communicationManager: CommunicationManager?

    private var peripheralManager: CBPeripheralManager!
    private var midiService: CBMutableService?
    private var midiCharacteristic: CBMutableCharacteristic?
    private var midiData: Data = Data()

    private var subscribedCentrals: Set<CBCentral> = []

    override init() {
        super.init()

        let peripheralIdentifier =
            Constants.rootIdentifier + ".PeripheralManager"

        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [
                CBPeripheralManagerOptionShowPowerAlertKey: true,
                CBPeripheralManagerOptionRestoreIdentifierKey:
                    peripheralIdentifier,
            ]
        )
    }

    @MainActor
    func addMidiService() {
        if midiService != nil {
            return
        }

        guard peripheralManager?.state == .poweredOn
        else {
            Logger.connectivity.error(
                "Cannot add Midi peripharal service because Bluetooth is not powered on"
            )
            return
        }

        midiService = CBMutableService(
            type: Constants.midiServiceUUID,
            primary: true,
        )

        guard let midiService else {
            Logger.connectivity.error(
                "Failed to create a midi peripheral service"
            )
            return
        }

        midiCharacteristic = CBMutableCharacteristic(
            type: Constants.midiCharacteristicUUID,
            properties: [
                .read, .writeWithoutResponse, .notify,
                .notifyEncryptionRequired,
            ],
            value: nil,
            permissions: [
                .readable, .writeable, .readEncryptionRequired,
                .writeEncryptionRequired,
            ]
        )

        guard let midiCharacteristic
        else {
            Logger.connectivity.error(
                "Failed to create a midi peripheral characteristic"
            )
            return
        }

        print("created service and characteristic")
        midiService.characteristics = [midiCharacteristic]
        midiService.includedServices = []
        peripheralManager!.add(midiService)
    }

    func startAdvertizing() {
        guard !isAdvertizing else { return }

        guard !peripheralManager.isAdvertising else {
            isAdvertizing = true
            return
        }

        addMidiService()

        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [
                Constants.midiServiceUUID
            ],
            CBAdvertisementDataLocalNameKey: peripheralName,
        ])
    }

    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        isAdvertizing = false
    }

    func send(_ data: Data, to centralId: UUID) {
        guard let midiCharacteristic else {
            Logger.connectivity.warning(
                "No MIDI characteristic available to send data to central with id: \(centralId)"
            )
            return
        }

        guard
            let remote = communicationManager?.remotes.first(where: {
                $0.id == centralId
            })
        else {
            Logger.connectivity.warning(
                "Could not send data to remote with id: \(centralId)"
            )
            return
        }

        let central: CBCentral? =
            switch remote.interface {
            case .midi:
                nil
            case .bluetooth(_, let destination):
                destination
            }

        if let central {
            print("...updating MIDI characteristic value")
            peripheralManager.updateValue(
                data,
                for: midiCharacteristic,
                onSubscribedCentrals: [central]
            )
        } else {
            Logger.connectivity.warning(
                "Could not send data to remote with id: \(centralId) that has not Bluetooth central"
            )
            return
        }
    }
}

extension BluetoothPeripheral: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            Logger.connectivity.info("Bluetooth peripheral is powered on")
        case .poweredOff:
            Logger.connectivity.info("Bluetooth peripheral is powered off")
        case .unauthorized:
            Logger.connectivity.warning(
                "Bluetooth is not authorized to have a local peripheral"
            )
        default:
            break
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        willRestoreState dict: [String: Any]
    ) {
        print("will restore: ", dict)

        let previousServices =
            dict[CBPeripheralManagerRestoredStateServicesKey]
            as? [CBMutableService] ?? []

        DispatchQueue.main.async {
            guard previousServices.count > 0 else {
                return
            }

            self.midiService = previousServices.first(where: {
                $0.uuid == Constants.midiServiceUUID
            })

            self.midiCharacteristic =
                self.midiService?.characteristics?.first(where: {
                    $0.uuid == Constants.midiCharacteristicUUID
                })
                as? CBMutableCharacteristic

            if let characteristic = self.midiCharacteristic,
                let centrals = characteristic.subscribedCentrals
            {
                centrals.forEach { central in
                    self.subscribedCentrals.insert(central)
                    if let remote = self.communicationManager?.remotes.contains(
                        where: {
                            $0.id == central.identifier
                        }) as? RemoteDetails
                    {
                        if case .bluetooth(let formerPeripheral, _) = remote
                            .interface
                        {
                            remote.interface = .bluetooth(
                                formerPeripheral,
                                central
                            )
                            remote.state = .connected
                        }
                    } else {
                        self.communicationManager?.remotes.append(
                            RemoteDetails(
                                id: central.identifier,
                                name: central.identifier.uuidString,
                                interface: .bluetooth(nil, central),
                                state: .connected
                            )
                        )
                    }
                }
            }
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: (any Error)?
    ) {
        DispatchQueue.main.async {
            if let error {
                self.midiService = nil
                self.midiCharacteristic = nil
                Logger.connectivity.error(
                    "Peripheral error while adding MIDI service: \(error.localizedDescription)"
                )
                return
            }
            print("***")
            print("confirmed added service: ", service)
            print("midiService: ", self.midiService ?? "<NONE>")
        }
    }

    func peripheralManagerDidStartAdvertising(
        _ peripheral: CBPeripheralManager,
        error: (any Error)?
    ) {
        print("***")
        print("Bluetooth peripheral is advertizing")
        self.isAdvertizing = peripheral.isAdvertising

        if let error {
            DispatchQueue.main.async {
                self.isAdvertizing = false
                Logger.connectivity.error(
                    "Peripheral error while starting advertising: \(error.localizedDescription)"
                )
            }
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        print("***")
        print("new subscriber: ", central)
        print("characteristic: ", characteristic)

        DispatchQueue.main.async {
            self.subscribedCentrals.insert(central)
            if let remote = self.communicationManager?.remotes
                .first(
                    where: {
                        $0.id == central.identifier
                    })
            {
                if case .bluetooth(let formerPeripheral, _) = remote.interface {
                    remote.interface = .bluetooth(formerPeripheral, central)
                    remote.state = .connected
                }
            } else {
                self.communicationManager?.remotes.append(
                    RemoteDetails(
                        id: central.identifier,
                        name: central.identifier.uuidString,
                        interface: .bluetooth(nil, central),
                        state: .connected
                    )
                )
            }
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        DispatchQueue.main.async {
            if let remoteIndex = self.communicationManager?.remotes
                .firstIndex(
                    where: {
                        $0.id == central.identifier
                    })
            {
                self.communicationManager?.remotes[remoteIndex].state =
                    .disconnected
            }
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveRead request: CBATTRequest
    ) {
        request.value = self.midiData
        peripheral.respond(to: request, withResult: .success)

    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        print("peripheral receive write request")
        if let firstRequest = requests.first {
            DispatchQueue.main.async {
                peripheral.respond(to: firstRequest, withResult: .success)
            }
        }

        for request in requests {
            let centralId = request.central.identifier
            if var packet: Data = request.value {
                packet = packet.dropFirst(request.offset)
                DispatchQueue.main.async {
                    if let remote = self.communicationManager?.remotes.first(
                        where: {
                            if case .bluetooth(_, let central) = $0.interface {
                                central?.identifier == centralId
                            } else {
                                false
                            }
                        })
                    {
                        self.communicationManager?.lastSource = remote.name
                        self.communicationManager?.lastMessages =
                            MidiMessage.decode(packet)
                    }
                }
            }
        }
        
//        peripheral.respond(to: requests.first!, withResult: .success)
    }
}
