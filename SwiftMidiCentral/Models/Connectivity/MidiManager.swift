//
//  MidiManager.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 22/11/2025.
//

import CoreBluetooth
import CoreMIDI
import Foundation
import OSLog

@Observable
class MidiManager: CommunicationManager {
    typealias NotificationDelegate = (MIDINotification) -> Void

    private var client: MIDIClientRef!
    private var outputPort: MIDIEndpointRef!
    private var inputPort: MIDIEndpointRef!

    var notificationDelegate: NotificationDelegate?

    private let startupTime = clock_gettime_nsec_np(CLOCK_MONOTONIC)

    override init() {
        super.init()
        self.reset()
        self.central = BluetoothCentral()
        self.central.communicationManager = self
        self.peripheral = BluetoothPeripheral()
        self.peripheral.communicationManager = self
        self.setup()
    }

    override func reset() {
        print("resetting")
        MIDIRestart()

        let deviceCount = MIDIGetNumberOfDevices()
        let extDeviceCount = MIDIGetNumberOfExternalDevices()

        print("Number of MIDI devices: \(deviceCount)")
        print("Number of external MIDI devices: \(extDeviceCount)")

        for i in 0..<deviceCount {
            let device = MIDIGetDevice(i)

            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(device, kMIDIPropertyName, &name)
            let deviceName: String? = name?.takeRetainedValue() as String?

            print(
                "\nFound MIDI device #\(i) named \"\(deviceName ?? "")\""
            )

            var driverOwner: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(
                device,
                kMIDIPropertyDriverOwner,
                &driverOwner
            )
            let deviceDriverOwner: String? =
                driverOwner?.takeRetainedValue() as String?

            var offline: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(device, kMIDIPropertyOffline, &offline)
            let deviceOffline: String? = offline?.takeRetainedValue() as String?

            var protocolId: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(
                device,
                kMIDIPropertyProtocolID,
                &protocolId
            )
            let deviceProtocol: String? =
                protocolId?.takeRetainedValue() as String?

            print(
                "\tDriver Owner: \(deviceDriverOwner ?? "\"\""), Offline: \(deviceOffline ?? "\"\""), Protocol: \(deviceProtocol ?? "\"\"")"
            )

            if (deviceDriverOwner ?? "").range(
                of: "bluetooth",
                options: .caseInsensitive
            ) != nil {
                print("\tRemoving Bluetooth MIDI device")
                MIDISetupRemoveDevice(device)
            }
        }
    }

    override func refresh() {
        print("refreshing")

        let activateStatus = MIDIBluetoothDriverActivateAllConnections()
        if activateStatus != noErr {
            Logger.connectivity.error(
                "Failed to activate all MIDI Bluetooth connections: \(activateStatus)"
            )
        }

        DispatchQueue.main.async {
            let deviceCount = MIDIGetNumberOfDevices()
            let extDeviceCount = MIDIGetNumberOfExternalDevices()

            print("Number of MIDI devices: \(deviceCount)")
            print("Number of external MIDI devices: \(extDeviceCount)")

            for i in 0..<deviceCount {
                let device = MIDIGetDevice(i)

                var name: Unmanaged<CFString>?
                MIDIObjectGetStringProperty(device, kMIDIPropertyName, &name)
                let deviceName: String? = name?.takeRetainedValue() as String?

                print(
                    "\nFound MIDI device #\(i) named \"\(deviceName ?? "")\""
                )

                var driverOwner: Unmanaged<CFString>?
                MIDIObjectGetStringProperty(
                    device,
                    kMIDIPropertyDriverOwner,
                    &driverOwner
                )
                let deviceDriverOwner: String? =
                    driverOwner?.takeRetainedValue() as String?

                var offline: Unmanaged<CFString>?
                MIDIObjectGetStringProperty(
                    device,
                    kMIDIPropertyOffline,
                    &offline
                )
                let deviceOffline: String? =
                    offline?.takeRetainedValue() as String?

                var protocolId: Unmanaged<CFString>?
                MIDIObjectGetStringProperty(
                    device,
                    kMIDIPropertyProtocolID,
                    &protocolId
                )
                let deviceProtocol: String? =
                    protocolId?.takeRetainedValue() as String?

                print(
                    "\tDriver Owner: \(deviceDriverOwner ?? "\"\""), Offline: \(deviceOffline ?? "\"\""), Protocol: \(deviceProtocol ?? "\"\"")"
                )

                let entities = MIDIDeviceGetNumberOfEntities(device)
                print("  Device #\(i) has \(entities) entities")

                for j in 0..<entities {
                    let entity = MIDIDeviceGetEntity(device, j)
                    MIDIObjectGetStringProperty(
                        entity,
                        kMIDIPropertyName,
                        &name
                    )
                    var offline: Unmanaged<CFString>?
                    MIDIObjectGetStringProperty(
                        entity,
                        kMIDIPropertyOffline,
                        &offline
                    )
                    let offlineStatus: String? =
                        offline?.takeRetainedValue() as String?
                    print(
                        "  Entity #\(j) is named \"\(name?.takeRetainedValue() as String? ?? "")\" with offline status \"\(offlineStatus ?? "")\""
                    )

                    let sources = MIDIEntityGetNumberOfSources(entity)
                    print("    Entity #\(j) has \(sources) sources")
                    let destinations = MIDIEntityGetNumberOfDestinations(entity)
                    print("    Entity #\(j) has \(destinations) destinations")

                    // For now only the first source and destination are being used
                    if let deviceName {
                        let source: MIDIEndpointRef? =
                            sources > 0 ? MIDIEntityGetSource(entity, 0) : nil
                        let destination: MIDIEndpointRef? =
                            destinations > 0
                            ? MIDIEntityGetDestination(entity, 0) : nil

                        if let remote = self.remotes.first(where: {
                            $0.name == deviceName
                        }) {
                            remote.interface = .midi(
                                source: source,
                                destination: destination
                            )
                        } else {
                            self.remotes.append(
                                RemoteDetails(
                                    name: deviceName,
                                    interface: .midi(
                                        source: source,
                                        destination: destination
                                    )
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    override func connect(to id: UUID) throws {
        guard let remote = remotes.first(where: { $0.id == id })
        else {
            Logger.connectivity.debug(
                "Could not find remote with ID \(id) to connect to"
            )
            return
        }

        remote.enableReception = true

        if case .bluetooth(let peripheral, _) = remote.interface,
            peripheral != nil
        {
            try? self.central.connect(to: remote.id)
        } else {
            if case .midi(let source, _) = remote.interface, let source {
                _ = withUnsafeMutablePointer(to: &remote.name) { pointer in
                    MIDIPortConnectSource(self.inputPort, source, pointer)
                }
            }
            remote.state = .connected
        }
    }

    override func disconnect(from id: UUID) throws {
        guard let remote = remotes.first(where: { $0.id == id })
        else {
            Logger.connectivity.debug(
                "Could not find remote with ID \(id) to disconnect from"
            )
            return
        }

        remote.enableReception = false

        if case .bluetooth = remote.interface {
            try? self.central.disconnect(from: remote.id)
        } else {
            if case .midi(let source, _) = remote.interface, let source {
                MIDIPortDisconnectSource(self.inputPort, source)
            }
            remote.state = .disconnected
        }
    }

    override func send(packets: [UInt32]) {
        guard !packets.isEmpty else { return }

        guard
            let remote = self.remotes.first(where: {
                $0.id == selectedDestination
            })
        else {
            Logger.connectivity.error("\(Localized.localUnsetDestination)")
            return
        }

        switch remote.interface {
        case .midi(_, let destination):
            // Send through Core MIDI end point if available
            if let destination {
                coreSend(packets: packets, to: destination)
            } else {
                Logger.connectivity.warning("")
            }
            break
        case .bluetooth(let peripheral, let central):
            if peripheral != nil {
                // Send through Bluetooth peripheral
                peripheralSend(packets: packets, to: remote)
            } else if let destination = central {
                // Send through Bluetooth central
                centralSend(packets: packets, to: destination)
            }
        }
    }

    private func deviceName(for endPoint: MIDIEndpointRef) -> String? {
        var deviceName: String? = nil
        var entity = MIDIClientRef()
        var device = MIDIDeviceRef()
        var name: Unmanaged<CFString>?
        var status = MIDIEndpointGetEntity(endPoint, &entity)

        if status == noErr {
            status = MIDIEntityGetDevice(entity, &device)
        }

        if status == noErr {
            MIDIObjectGetStringProperty(device, kMIDIPropertyName, &name)
            deviceName = name?.takeRetainedValue() as String?
        }

        return deviceName
    }

    private func coreSend(packets: [UInt32], to destination: MIDIEntityRef) {
        print("Sending data through core MIDI")
        var eventList = MIDIEventList()
        var currentPacket = MIDIEventListInit(&eventList, ._1_0)
        let listSize = (MemoryLayout.size(ofValue: eventList.packet) - 12) / 4

        let nanoSecondsSinceStartup =
            clock_gettime_nsec_np(CLOCK_MONOTONIC) - startupTime
        var stamp = MIDITimeStamp(nanoSecondsSinceStartup)
        let stampDelay = MIDITimeStamp(100_000_000)

        let packetSize = MemoryLayout.size(ofValue: UInt32()) / 4

        for var packet in packets {
            currentPacket = MIDIEventListAdd(
                &eventList,
                listSize,
                currentPacket,
                stamp,
                packetSize,
                &packet
            )
            stamp += stampDelay
        }

        print("... sending data \(eventList)")
        let midiStatus = MIDISendEventList(
            self.outputPort,
            destination,
            &eventList
        )
        if midiStatus != noErr {
            Logger.connectivity.error(
                "Failed to send MIDI event list (Status code: \(midiStatus)"
            )
        }
    }

    private func peripheralSend(packets: [UInt32], to remote: RemoteDetails) {
        print("Sending MIDI data through CBPeripheral")

        guard case .bluetooth(let destination, _) = remote.interface else {
            Logger.connectivity.error(
                "No Bluetooth peripheral found to send data to"
            )
            return
        }

        let maxSize =
            destination?.maximumWriteValueLength(for: .withoutResponse) ?? 256

        let elapsedTime = (clock_gettime_nsec_np(CLOCK_MONOTONIC) - startupTime)
        let encodedPackets = MidiMessage.encode(
            packets,
            maxSize: maxSize,
            elapsedTime: elapsedTime
        )

        print("... sending data \(encodedPackets)")
        central.send(encodedPackets, to: remote)
    }

    private func centralSend(packets: [UInt32], to destination: CBCentral) {
        print("Sending MIDI data through CBCentral")
        let maxSize = destination.maximumUpdateValueLength

        let elapsedTime = (clock_gettime_nsec_np(CLOCK_MONOTONIC) - startupTime)
        let encodedPackets = MidiMessage.encode(
            packets,
            maxSize: maxSize,
            elapsedTime: elapsedTime
        )

        print("... sending data \(encodedPackets)")
        encodedPackets.forEach {
            peripheral.send($0, to: destination.identifier)
        }
    }

    private func setup() {
        var status: OSStatus

        // Create MIDI Client
        var clientRef = MIDIClientRef()
        status = MIDIClientCreateWithBlock(
            "SwiftMidiDemo" as CFString,
            &clientRef
        ) { notificationPtr in
            let notification = notificationPtr.pointee

            switch notification.messageID {
            case .msgSetupChanged:
                Logger.connectivity.debug("🔄 MIDI Setup Changed")
                self.refresh()

            case .msgObjectAdded:
                let rawPtr = UnsafeRawPointer(notificationPtr)
                let message = rawPtr.assumingMemoryBound(
                    to: MIDIObjectAddRemoveNotification.self
                ).pointee
                Logger.connectivity.debug(
                    "➕ MIDI \(message.childType.rawValue) added: \(message.child)"
                )
                self.refresh()

            case .msgObjectRemoved:
                let rawPtr = UnsafeRawPointer(notificationPtr)
                let message = rawPtr.assumingMemoryBound(
                    to: MIDIObjectAddRemoveNotification.self
                ).pointee
                Logger.connectivity.debug(
                    "➖ MIDI \(message.childType.rawValue) removed: \(message.child)"
                )
                self.refresh()

            case .msgPropertyChanged:
                let rawPtr = UnsafeRawPointer(notificationPtr)
                let message = rawPtr.assumingMemoryBound(
                    to: MIDIObjectPropertyChangeNotification.self
                ).pointee
                Logger.connectivity.debug(
                    "🔧 MIDI \(message.object) property \(message.propertyName.takeUnretainedValue()) changed."
                )
            case .msgThruConnectionsChanged, .msgSerialPortOwnerChanged:
                Logger.connectivity.debug(
                    "⚠️ MIDI Thru connection was created or destroyed"
                )

            case .msgIOError:
                let rawPtr = UnsafeRawPointer(notificationPtr)
                let message = rawPtr.assumingMemoryBound(
                    to: MIDIIOErrorNotification.self
                ).pointee
                Logger.connectivity.debug(
                    "🚫 MIDI I/O error \(message.errorCode) occurred"
                )

            default:
                Logger.connectivity.debug("⁉️ Untracked MIDI Notification")
            }

            if let delegate = self.notificationDelegate {
                delegate(notification)
            }
        }

        guard status == noErr else {
            Logger.connectivity.warning(
                "❌ Failed to create MIDI client: \(status)"
            )
            return
        }

        self.client = clientRef
        Logger.connectivity.debug("✅ MIDI Client created successfully")

        // Create Input Port
        var inputPortRef = MIDIPortRef()
        status = MIDIInputPortCreateWithProtocol(
            clientRef,
            "SwiftMidiDemo Input" as CFString,
            ._1_0,
            &inputPortRef,
            processEventList
        )

        if status == noErr {
            self.inputPort = inputPortRef
            Logger.connectivity.debug("✅ MIDI Input Port created successfully")
        } else {
            Logger.connectivity.warning(
                "❌ Failed to create MIDI input port: \(status)"
            )
        }

        // Create Output Port
        var outputPortRef = MIDIPortRef()
        status = MIDIOutputPortCreate(
            clientRef,
            "SwiftMidiDemo Output" as CFString,
            &outputPortRef
        )

        if status == noErr {
            self.outputPort = outputPortRef
            Logger.connectivity.debug("✅ MIDI Output Port created successfully")
        } else {
            Logger.connectivity.warning(
                "❌ Failed to create MIDI output port: \(status)"
            )
        }

        // Refresh device list
        refresh()
    }

    private func processEventList(
        _ eventList: UnsafePointer<MIDIEventList>,
        _ unsafeRawPointer: UnsafeMutableRawPointer?
    ) {
        let source: String =
            unsafeRawPointer?.load(as: String.self)
            ?? Localized.remoteUnknownDevice

        if let remote = self.remotes.first(where: { $0.name == source }),
            remote.enableReception
        {
            print("Processing event list received from ", source)
            self.lastSource = source

            let visitorContext = EventListVisitorContext()

            let pointerToContext = Unmanaged.passUnretained(visitorContext)
                .toOpaque()

            MIDIEventListForEachEvent(
                eventList,
                { unsafePointerToContext, stamp, message in
                    if message.type != .channelVoice1 { return }

                    guard let unsafePointerToContext else { return }

                    let visiteeContext = Unmanaged<EventListVisitorContext>
                        .fromOpaque(
                            unsafePointerToContext
                        ).takeUnretainedValue()

                    visiteeContext.messages.append(message)
                },
                pointerToContext
            )

            self.lastMessages.removeAll(keepingCapacity: true)
            visitorContext.messages.forEach { message in
                let decodedMessage =
                    MidiMessage.decode(message) ?? Localized.midiMessageUnknown
                self.lastMessages.append(decodedMessage)
            }
        } else {
            print("Received message from \(source), but reception is disabled")
        }
    }

}

private final class EventListVisitorContext {
    let stamp: UInt64 = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
    var messages: [MIDIUniversalMessage] = []
}
