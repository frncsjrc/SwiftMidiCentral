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
        self.setup()
    }

    override func refresh() {
        DispatchQueue.main.async {
            let activateStatus = MIDIBluetoothDriverActivateAllConnections()
            if activateStatus != noErr {
                Logger.connectivity.error(
                    "Failed to activate all MIDI Bluetooth connections: \(activateStatus)"
                )
            }

            // Get all sources
            let sourceCount = MIDIGetNumberOfSources()
            for i in 0..<sourceCount {
                var source = MIDIGetSource(i)
                var name: Unmanaged<CFString>?
                MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name)
                if let sourceName = name?.takeRetainedValue() as String? {
                    if let remoteIndex = self.remotes.firstIndex(where: {
                        $0.name == sourceName
                    }) {
                        self.remotes[remoteIndex].source = source
                        self.remotes[remoteIndex].state = .connected
                        if self.remotes[remoteIndex].enableReception {
                            MIDIPortConnectSource(
                                self.inputPort,
                                source,
                                &source
                            )
                        }
                    } else {
                        self.remotes.append(
                            RemoteDetails(
                                name: sourceName,
                                source: source,
                                state: .connected
                            )
                        )
                    }
                }
            }

            // Get all destinations
            let destCount = MIDIGetNumberOfDestinations()
            for i in 0..<destCount {
                let destination = MIDIGetDestination(i)
                var name: Unmanaged<CFString>?
                MIDIObjectGetStringProperty(
                    destination,
                    kMIDIPropertyName,
                    &name
                )
                if let destinationName = name?.takeRetainedValue() as String? {
                    if let remoteIndex = self.remotes.firstIndex(where: {
                        $0.name == destinationName
                    }) {
                        self.remotes[remoteIndex].destination = destination
                    } else {
                        self.remotes.append(
                            RemoteDetails(
                                name: destinationName,
                                destination: destination
                            )
                        )
                    }
                }
            }

            // Get all external devices
            let externalDeviceCount = MIDIGetNumberOfExternalDevices()
            for i in 0..<externalDeviceCount {
                let externalDevice = MIDIGetExternalDevice(i)
                var name: Unmanaged<CFString>?
                MIDIObjectGetStringProperty(
                    externalDevice,
                    kMIDIPropertyName,
                    &name
                )

                if let deviceName = name?.takeRetainedValue() as String? {
                    if let remoteIndex = self.remotes.firstIndex(where: {
                        $0.name == deviceName
                    }) {
                        self.remotes[remoteIndex].source = externalDevice
                        self.remotes[remoteIndex].destination = externalDevice
                    } else {
                        self.remotes.append(
                            RemoteDetails(
                                name: deviceName,
                                source: externalDevice,
                                destination: externalDevice
                            )
                        )
                    }
                }
            }
        }
    }

    override func connect(to peripheral: MIDIEndpointRef) {
        if let remoteIndex = self.remotes.firstIndex(where: {
            $0.source == peripheral
        }) {
            self.remotes[remoteIndex].enableReception = true
            if self.remotes[remoteIndex].state != .connected {
                try? central.connect(to: self.remotes[remoteIndex].id)
            } else if var source = self.remotes[remoteIndex].source {
                MIDIPortConnectSource(self.inputPort, source, &source)
            }
        }
    }

    override func disconnect(from peripheral: MIDIEndpointRef) {
        if let remoteIndex = self.remotes.firstIndex(where: {
            $0.source == peripheral
        }) {
            self.remotes[remoteIndex].enableReception = false
            if let source = self.remotes[remoteIndex].source {
                MIDIPortDisconnectSource(self.inputPort, source)
            }
        }
    }

    override func send(packets: [UInt32]) {
        guard !packets.isEmpty else { return }

        guard
            let destination = self.selectedDestination,
            let remote = self.remotes.first(where: { $0.id == destination })
        else {
            Logger.connectivity.error("\(Localized.localUnsetDestination)")
            return
        }

        if let remoteDestination = remote.destination {
            // Send through Core MIDI end point if available
            send(packets: packets, to: remoteDestination)
        } else {
            // Else assume this destination is a pure Bluetooth connection
            send(packets: packets, to: remote.id)
        }
    }

    private func send(packets: [UInt32], to destination: MIDIEntityRef) {
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

    private func send(packets: [UInt32], to destination: UUID) {
        guard
            let peripheral = remotes.first(where: { $0.id == destination })?
                .peripheral
        else {
            Logger.connectivity.error(
                "Remote with ID \(destination) has no attached Bluetooth peripheral"
            )
            return
        }

        guard
            let service = peripheral.services?.first(where: {
                $0.uuid == Constants.midiServiceUUID
            })
        else {
            Logger.connectivity.error(
                "No MIDI service found on peripheral \(peripheral.debugDescription)"
            )
            return
        }

        guard
            let cheracteristic = service.characteristics?.first(where: {
                $0.uuid == Constants.midiCharacteristicUUID
            })
        else {
            Logger.connectivity.error(
                "No MIDI data characteristic found on peripheral \(peripheral.debugDescription)"
            )
            return
        }

        let maxSize = peripheral.maximumWriteValueLength(for: .withoutResponse)

        let elapsedTime = (clock_gettime_nsec_np(CLOCK_MONOTONIC) - startupTime)
        let encodedPackets = MidiMessage.encode(
            packets,
            maxSize: maxSize,
            elapsedTime: elapsedTime
        )

        encodedPackets.forEach {
            peripheral.writeValue(
                $0,
                for: cheracteristic,
                type: .withoutResponse
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
                Logger.connectivity.debug("➕ MIDI Object Added")
                self.refresh()

            case .msgObjectRemoved:
                Logger.connectivity.debug("➖ MIDI Object Removed")
                self.refresh()

            case .msgPropertyChanged:
                Logger.connectivity.debug("🔧 MIDI Property Changed")

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
            &inputPortRef
        ) { eventList, unsafeRawPointer in
            let source: MIDIEndpointRef? = unsafeRawPointer?.load(
                as: MIDIEndpointRef.self
            )
            self.processEventList(eventList, source)
        }

        if status == noErr {
            Logger.connectivity.debug("✅ MIDI Input Port created successfully")

            // Connect to all available MIDI sources
            let sourceCount = MIDIGetNumberOfSources()
            for i in 0..<sourceCount {
                let source = MIDIGetSource(i)
                status = MIDIPortConnectSource(inputPortRef, source, nil)
                if status == noErr {
                    var name: Unmanaged<CFString>?
                    MIDIObjectGetStringProperty(
                        source,
                        kMIDIPropertyName,
                        &name
                    )
                    let sourceName =
                        name?.takeRetainedValue() as String? ?? "Unknown"
                    Logger.connectivity.debug(
                        "✅ Connected to MIDI source: \(sourceName)"
                    )
                }
            }
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
            Logger.connectivity.debug("✅ MIDI Output Port created successfully")

            // Find first available destination
            let destCount = MIDIGetNumberOfDestinations()
            if destCount > 0 {
                self.outputPort = MIDIGetDestination(0)
                var name: Unmanaged<CFString>?
                MIDIObjectGetStringProperty(
                    self.outputPort!,
                    kMIDIPropertyName,
                    &name
                )
                let destName = name?.takeRetainedValue() as String? ?? "Unknown"
                Logger.connectivity.debug(
                    "✅ Output endpoint set to: \(destName)"
                )
            }
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
        _ ref: MIDIEndpointRef?
    ) {
        let visitorContext = EventListVisitorContext(ref)
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

        self.lastSource =
            if let source = remotes.first(where: {
                $0.source == visitorContext.ref
            }) {
                source.description
            } else {
                Localized.remoteUnknownDevice
            }

        self.lastMessages.removeAll(keepingCapacity: true)
        visitorContext.messages.forEach { message in
            let decodedMessage =
                MidiMessage.decode(message) ?? Localized.midiMessageUnknown
            self.lastMessages.append(decodedMessage)
        }
    }

}

private final class EventListVisitorContext {
    let ref: MIDIEndpointRef?
    let stamp: UInt64 = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
    var messages: [MIDIUniversalMessage] = []

    init(_ ref: MIDIEndpointRef?) {
        self.ref = ref
    }
}
