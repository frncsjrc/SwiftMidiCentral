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
            for remote in self.remotes {
                remote.state = .disconnected
            }

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

                let interface: RemoteInterface =
                    (deviceDriverOwner?.lowercased().contains("bluetooth")
                        ?? false) ? .bluetooth : .wired

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
                            (source != nil && $0.source == source)
                                || (destination != nil
                                    && $0.destination == destination)
                        }) {
                            remote.interface = interface
                            remote.source = source
                            remote.destination = destination
                            remote.state = .connected
                        } else {
                            self.remotes.append(
                                RemoteDetails(
                                    name: deviceName,
                                    interface: interface,
                                    source: source,
                                    destination: destination,
                                    state: .connected
                                )
                            )
                        }
                    }
                }
            }
        }
        
        checkSelectedDestination()
    }

    override func connect(to remote: RemoteDetails) throws {
        if let source = remote.source {
            MIDIPortConnectSource(inputPort, source, &remote.source!)
            print(
                "Source \(remote.name) is now connected to the MIDI inpur port"
            )
        }
        
        remote.enableReception = true
        print("Reception from \(remote.name) is now enabled")
    }

    override func disconnect(from remote: RemoteDetails) throws {
        if let source = remote.source {
            MIDIPortDisconnectSource(inputPort, source)
            print(
                "Source \(remote.name) has been disconnected from the MIDI inpur port"
            )
        }

        remote.enableReception = false
        print("Reception from \(remote.name) has been disabled")
        
        checkSelectedDestination()
    }

    override func send(packets: [UInt32]) {
        guard !packets.isEmpty else { return }

        guard
            let destination = selectedDestination
        else {
            Logger.connectivity.error("\(Localized.localUnsetDestination)")
            return
        }

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
        _ refConn: UnsafeMutableRawPointer?
    ) {
        guard
            let source: MIDIEndpointRef = refConn?.load(as: MIDIEndpointRef.self),
            let remote = self.remotes.first(where: { $0.source == source })
        else {
            print("Received message from \(Localized.remoteUnknownDevice)")
            return
        }

        if remote.enableReception
        {
            print("Processing event list received from ", source)
            self.lastSource = remote.name

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
    
    private func checkSelectedDestination() {
        if self.selectedDestination == nil,
            let remote = self.remotes.first(where: { $0.destination != nil }
            )
        {
            self.selectedDestination = remote.destination
        }
    }
}

private final class EventListVisitorContext {
    let stamp: UInt64 = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
    var messages: [MIDIUniversalMessage] = []
}
