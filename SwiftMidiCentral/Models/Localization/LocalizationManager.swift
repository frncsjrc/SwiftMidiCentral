//
//  LocalizationManager.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 21/11/2025.
//

import Foundation

struct Localized {
    static var appLocale: Locale = .autoupdatingCurrent
    
    static let bluetoothUnavailable = String(
        localized: "bluetooth.unavailable",
        defaultValue: "Bluetooth is not available",
        locale: appLocale,
        comment:
            "Log message when Bluetooth is not available for scanning or connection"
    )

    static let bluetoothUnsupported = String(
        localized: "bluetooth.unsupported",
        defaultValue: "Bluetooth is not supported",
        locale: appLocale,
        comment:
            "Log message when Bluetooth state gets updated as being not supported"
    )

    static let bluetoothPoweredOn = String(
        localized: "bluetooth.poweredOn",
        defaultValue: "Bluetooth is powered on",
        locale: appLocale,
        comment:
            "Log message when Bluetooth state gets updated as being powered on"
    )

    static let bluetoothPoweredOff = String(
        localized: "bluetooth.poweredOff",
        defaultValue: "Bluetooth is powered off",
        locale: appLocale,
        comment:
            "Log message when Bluetooth state gets updated as being powered off"
    )

    static let bluetoothIsNotAuthorized = String(
        localized: "bluetooth.isNotAuthorized",
        defaultValue: "Bluetooth is not authorized",
        locale: appLocale,
        comment:
            "Log message when Bluetooth state gets updated as being not authorized"
    )

    static let remoteUnknownDevice = String(
        localized: "remote.unknownDevice",
        defaultValue: "Unknown device",
        locale: appLocale,
        comment: "Unknown device"
    )

    static func bluetoothCannotConnectToUnknownPeripheral(_ id: UUID) -> String
    {
        String(
            localized: "bluetooth.cannotConnectToUnknownPeripheral",
            defaultValue:
                "Bluetooth cannot connect to unknown peripheral with ID: \(String(describing: id))",
            locale: appLocale,
            comment:
                "Log message when Bluetooth is asked to connect to a peripheral for which the UUID passed as argument is unknown"
        )
    }

    static func bluetoothDidDiscoverPeripheral(_ name: String) -> String {
        String(
            localized: "bluetooth.bluetoothDiscoveredDevice",
            defaultValue: "Bluetooth did discover MIDI peripheral: \(name)",
            locale: appLocale,
            comment:
                "Log message when Bluetooth discovers a new MIDI peripheral with full name passed by argument"
        )
    }

    static func bluetoothDidConnectToPeripheral(_ peripheral: String) -> String
    {
        String(
            localized: "bluetooth.didConnectTo",
            defaultValue: "Bluetooth did connect to \(peripheral)",
            locale: appLocale,
            comment:
                "Log message when Bluetooth did connect to the peripheral specified as argument"
        )
    }

    static let bluetoothUnknownError = String(
        localized: "bluetooth.unknownError",
        defaultValue: "Unknown Bluetooth error",
        locale: appLocale,
        comment: "Description for an unknown Bluetooth error"
    )

    static func bluetoothFailedToConnectToPeripheral(
        _ peripheral: String,
        with error: String
    ) -> String {
        String(
            localized: "bluetooth.failedToConnectTo",
            defaultValue:
                "Bluetooth failed to connect to \(peripheral): \(error)",
            locale: appLocale,
            comment:
                "Log message when Bluetooth failed to connect to the peripheral specified as first argument and returned the error passed as second argument"
        )
    }

    static func bluetoothGotDisconnectedFromPeripheral(
        _ peripheral: String,
        with error: String
    ) -> String {
        String(
            localized: "bluetooth.gotDisconnectedFrom",
            defaultValue:
                "Bluetooth got disconnected from \(peripheral) with error: \(error)",
            locale: appLocale,
            comment:
                "Log message when Bluetooth got disconnected from the peripheral specified as first argument due to the error passed as second argument"
        )
    }

    static func bluetoothDidDisconnectFromPeripheral(_ peripheral: String)
        -> String
    {
        String(
            localized: "bluetooth.didDisconnectFrom",
            defaultValue: "Bluetooth did disconnect from \(peripheral)",
            locale: appLocale,
            comment:
                "Log message when Bluetooth did disconnect from the peripheral specified as argument"
        )
    }

    static func localCentralCannotConnectToPeripheral(with identifier: UUID)
        -> String
    {
        String(
            localized: "local.centralCannotConnectToPeripheral",
            defaultValue:
                "Local central cannot connect to unknown peripheral with UUID: \(identifier.uuidString)",
            locale: appLocale,
            comment:
                "Log message when local central cannot connect to the unknown peripheral which identifier is specified as argument"
        )
    }

    static func localCentralCannotDisconnectFromPeripheral(
        with identifier: UUID
    ) -> String {
        String(
            localized: "local.centralCannotDisconnectFromPeripheral",
            defaultValue:
                "Local central cannot disconnect from unknown peripheral with UUID: \(identifier.uuidString)",
            locale: appLocale,
            comment:
                "Log message when local central cannot disconnect from the unknown peripheral which identifier is specified as argument"
        )
    }

    static func midiManagerSendError(_ error: Error) -> String {
        String(
            localized: "midi.managerSendError",
            defaultValue:
                "MIDI manager send error: \(String(describing: error))",
            locale: appLocale,
            comment:
                "Log message when an error passed as argument is thrown while sending a MIDI message"
        )
    }

    static let localManagerRefresh = String(
        localized: "local.managerRefresh",
        defaultValue: "Local manager is refreshing",
        locale: appLocale,
        comment: "Log message when the local manager is refreshing"
    )
    
    static func localUnknownSourceName(_ peripheral: UInt32) -> String {
        String(
            localized: "local.unknownSourceName",
            defaultValue: "Unknown source name for peripheral: \(peripheral)",
            locale: appLocale,
            comment: "Returned value when the local manager cannot retrieve a source name for an unknown peripheral"
        )
    }
    
    static func localUnknownDestinationName(_ peripheral: UUID) -> String {
        String(
            localized: "local.unknownSourceName",
            defaultValue: "Unknown destination name for peripheral: \(peripheral.uuidString)",
            locale: appLocale,
            comment: "Returned value when the local manager cannot retrieve a destination name for an unknown peripheral"
        )
    }
    
    static let localUnsetDestination = String(
        localized: "local.unsetDestination",
        defaultValue: "No destination selected to send packets to",
        comment: "Returned value when the local manager has no selected destination"
    )

    static func midiMessageSystemExclusive(_ sequence: String) -> String {
        String(
            localized: "midi.messageSystemExclusive",
            defaultValue: "SysEx: \(sequence)",
            locale: appLocale,
            comment:
                "Text to display when a system exclusive MIDI message is received with a sequence of hexadecimal values passed as argument"
        )
    }

    static func midiMessageNoteOn(
        _ channel: UInt8,
        _ key: UInt8,
        _ velocity: UInt8
    ) -> String {
        String(
            localized: "midi.messageNoteOn",
            defaultValue:
                "Note on: channel \(channel + 1), key \(key), velocity \(velocity)",
            locale: appLocale,
            comment: "Text to display when a note on MIDI message is received"
        )
    }

    static func midiMessageNoteOff(
        _ channel: UInt8,
        _ key: UInt8,
        _ velocity: UInt8
    ) -> String {
        String(
            localized: "midi.messageNoteOff",
            defaultValue:
                "Note off: channel \(channel + 1), key \(key), velocity \(velocity)",
            locale: appLocale,
            comment: "Text to display when a note off MIDI message is received"
        )
    }

    static func midiMessagePolyPressure(
        _ channel: UInt8,
        _ key: UInt8,
        _ pressure: UInt8
    ) -> String {
        String(
            localized: "midi.messagePolyPressure",
            defaultValue:
                "Poly pressure: channel \(channel + 1), key \(key), aftertouch \(pressure)",
            locale: appLocale,
            comment:
                "Text to display when a poly pressure MIDI message is received"
        )
    }

    static func midiMessageControlChange(
        _ channel: UInt8,
        _ control: UInt8,
        _ value: UInt8
    ) -> String {
        String(
            localized: "midi.messageControlChange",
            defaultValue:
                "Control change: channel \(channel + 1), control \(control), value \(value)",
            locale: appLocale,
            comment:
                "Text to display when a control change MIDI message is received"
        )
    }

    static func midiMessageChannelPressure(
        _ channel: UInt8,
        _ pressure: UInt8
    ) -> String {
        String(
            localized: "midi.messageChannelPressure",
            defaultValue:
                "Channel pressure: channel \(channel + 1), aftertouch \(pressure)",
            locale: appLocale,
            comment:
                "Text to display when a channel pressure MIDI message is received"
        )
    }

    static func midiMessagePitchBend(
        _ channel: UInt8,
        _ bend: UInt16
    ) -> String {
        String(
            localized: "midi.messagePitchBend",
            defaultValue:
                "Pitch bend: channel \(channel + 1), bend \(bend)",
            locale: appLocale,
            comment:
                "Text to display when a pitch bend MIDI message is received"
        )
    }

    static func midiMessageProgramChange(
        _ channel: UInt8,
        _ program: UInt8
    ) -> String {
        String(
            localized: "midi.messageProgramChange",
            defaultValue:
                "Program change: channel \(channel + 1), program \(program)",
            locale: appLocale,
            comment:
                "Text to display when a program change MIDI message is received"
        )
    }
    
    static let midiMessageUnknown = String(
        localized: "midi.messageUnknown",
        defaultValue: "Unknown message",
        locale: appLocale,
        comment: "Text to display when an unknown MIDI message is received"
    )
    
    static let midiMessageUnsupported = String(
        localized: "midi.messageUnsupported",
        defaultValue: "Unsupported message",
        locale: appLocale,
        comment: "Text to display when receiving an unsupported MIDI message (for instance a sysex message)"
    )
    
    static let setupViewStartScanning = String(
        localized: "view.setupStartScanning",
        defaultValue: "Start scanning",
        locale: appLocale,
        comment: "Text for the button in the setup view that starts scanning for MIDI devices"
    )
    
    static let setupViewStopScanning = String(
        localized: "view.setupStopScanning",
        defaultValue: "Stop scanning",
        locale: appLocale,
        comment: "Text for the button in the setup view that stops scanning for MIDI devices"
    )
    
    static let setupViewRefresh = String(
        localized: "view.setupRefresh",
        defaultValue: "Refresh",
        locale: appLocale,
        comment: "Text for the button in the setup view that refreshes the list of available MIDI devices"
    )
    
    static let setupViewUnknownSource = String(
        localized: "view.setupUnknownSource",
        defaultValue: "No source",
        locale: appLocale,
        comment: "Text to display in the setup view when a remote source is not defined"
    )
    
    static let setupViewUnknownDestination = String(
        localized: "view.setupUnknownDestination",
        defaultValue: "No destination",
        locale: appLocale,
        comment: "Text to display in the setup view when a remote destination is not defined"
    )
    
    static let outgoingViewTitle = String(
        localized: "view.outgoingTitle",
        defaultValue: "Outgoing",
        locale: appLocale,
        comment: "Title text for the section of the UI allowing to send MIDI messages"
    )
    
    static let outgoingViewNoDestinations = String(
        localized: "view.outgoingNoDestinationsLabel",
        defaultValue: "Please refresh or scan for devices.",
        locale: appLocale,
        comment: "Text displayed when there are no MIDI destinations available, asking to scan or refresh."
    )
    
    static let outgoingViewDestinationLabel = String(
        localized: "view.outgoingDestinationLabel",
        defaultValue: "Destination",
        locale: appLocale,
        comment: "Destination label text for the section of the UI allowing to send MIDI messages"
    )
    
    static let outgoingViewSelectDestination = String(
        localized: "view.outgoingSelectDestination",
        defaultValue: "Select a destination",
        locale: appLocale,
        comment: "Text that appears when the user hasn't selected a MIDI destination"
    )
    
    static let incomingViewTitle = String(
        localized: "view.incomingTitle",
        defaultValue: "Incoming",
        locale: appLocale,
        comment: "Title text for the section of the UI allowing to receive MIDI messages"
    )
    
    static let incomingViewSourceLabel = String(
        localized: "view.incomingSourceLabel",
        defaultValue: "Source",
        locale: appLocale,
        comment: "Source label text for the section of the UI allowing to receive MIDI messages"
    )

}
