//
//  TestMidiMessage.swift
//  SwiftMidiCentralTests
//
//  Created by François Jean Raymond CLÉMENT on 13/12/2025.
//

import CoreMIDI
import OSLog
import Testing

@testable import SwiftMidiCentral

@Suite("MIDI Message Tests")
@MainActor
struct TestMidiMessage {

    @Test("Decode Bad Message") func testDecodeBadMessage() async throws {
        let logStartDate = Date()
        Logger.swiftMidiCentralSubsystem = "TestMidiMessage.DecodeNoteOn"

        let dummy: UInt8 = 0x00
        let channel: UInt8 = 0x05
        let note: UInt8 = 0x22
        let pressure: UInt8 = 0x79

        var expectedLog: [String] = []

        var packets = Data([0xA0 | channel, note, pressure])
        var decodedMessages = MidiMessage.decode(packets)
        #expect(decodedMessages == [])
        expectedLog.append("Invalid MIDI packet: \(packets)")

        packets = Data([dummy, dummy, channel, note, pressure])
        decodedMessages = MidiMessage.decode(packets)
        #expect(decodedMessages == [])
        expectedLog.append(
            "Invalid MIDI packet status 0 at index 2 in \(packets)"
        )

        let message = MIDIUniversalMessage()
        let decodedMessage = MidiMessage.decode(message)
        #expect(decodedMessage == nil)

        let logStore = try! OSLogStore(scope: .currentProcessIdentifier)

        let initialLogEntries = try! logStore.getEntries(
            at: logStore.position(date: logStartDate),
            matching: Logger.connectivityFilter
        )
        for (index, entry) in initialLogEntries.enumerated() {
            guard index < expectedLog.count else {
                print(
                    "Unexpected log entry at index \(index): \(entry.composedMessage)"
                )
                continue
            }
            #expect(entry.composedMessage == expectedLog[index])
        }
    }

    @Test("Decode Note Off") func testDecodeNoteOff() async throws {
        let dummy: UInt8 = 0x00
        let channel: UInt8 = 0x05
        let note: UInt8 = 0x22
        let velocity: UInt8 = 0x79
        let expectedMessages = [
            Localized.midiMessageNoteOff(channel, note, velocity)
        ]

        let packets = Data([dummy, dummy, 0x80 | channel, note, velocity])
        let decodedMessages = MidiMessage.decode(packets)
        #expect(decodedMessages == expectedMessages)

        let message = MIDIUniversalMessage(
            type: .channelVoice1,
            group: 0,
            reserved: (0, 0, 0),
            .init(
                channelVoice1: .init(
                    status: .noteOff,
                    channel: channel,
                    reserved: (0, 0, 0),
                    .init(note: .init(number: note, velocity: velocity))
                )
            )
        )

        try #require(message.type == .channelVoice1)
        let decodedMessage = MidiMessage.decode(message)
        #expect(decodedMessage == expectedMessages.first!)
    }

    @Test("Decode Note On") func testDecodeNoteOn() async throws {
        let dummy: UInt8 = 0x00
        let channel: UInt8 = 0x05
        let note: UInt8 = 0x22
        let velocity: UInt8 = 0x79
        let expectedMessages = [
            Localized.midiMessageNoteOn(channel, note, velocity)
        ]

        let packets = Data([dummy, dummy, 0x90 | channel, note, velocity])
        let decodedMessages = MidiMessage.decode(packets)
        #expect(decodedMessages == expectedMessages)

        let message = MIDIUniversalMessage(
            type: .channelVoice1,
            group: 0,
            reserved: (0, 0, 0),
            .init(
                channelVoice1: .init(
                    status: .noteOn,
                    channel: channel,
                    reserved: (0, 0, 0),
                    .init(note: .init(number: note, velocity: velocity))
                )
            )
        )

        try #require(message.type == .channelVoice1)
        let decodedMessage = MidiMessage.decode(message)
        #expect(decodedMessage == expectedMessages.first!)
    }

    @Test("Decode Poly Pressure") func testDecodePolyPressure() async throws {
        let dummy: UInt8 = 0x00
        let channel: UInt8 = 0x05
        let note: UInt8 = 0x22
        let pressure: UInt8 = 0x79
        let expectedMessages = [
            Localized.midiMessagePolyPressure(channel, note, pressure)
        ]

        let packets = Data([dummy, dummy, 0xA0 | channel, note, pressure])
        let decodedMessages = MidiMessage.decode(packets)
        #expect(decodedMessages == expectedMessages)

        let message = MIDIUniversalMessage(
            type: .channelVoice1,
            group: 0,
            reserved: (0, 0, 0),
            .init(
                channelVoice1: .init(
                    status: .polyPressure,
                    channel: channel,
                    reserved: (0, 0, 0),
                    .init(
                        polyPressure: .init(
                            noteNumber: note,
                            pressure: pressure
                        )
                    )
                )
            )
        )

        try #require(message.type == .channelVoice1)
        let decodedMessage = MidiMessage.decode(message)
        #expect(decodedMessage == expectedMessages.first!)
    }

    @Test("Decode Control Change") func testDecodeControlChange() async throws {
        let dummy: UInt8 = 0x00
        let channel: UInt8 = 0x05
        let control: UInt8 = 0x22
        let value: UInt8 = 0x79
        let expectedMessages = [
            Localized.midiMessageControlChange(channel, control, value)
        ]

        let packets = Data([dummy, dummy, 0xB0 | channel, control, value])
        let decodedMessages = MidiMessage.decode(packets)
        #expect(decodedMessages == expectedMessages)

        let message = MIDIUniversalMessage(
            type: .channelVoice1,
            group: 0,
            reserved: (0, 0, 0),
            .init(
                channelVoice1: .init(
                    status: .controlChange,
                    channel: channel,
                    reserved: (0, 0, 0),
                    .init(
                        controlChange: .init(
                            index: control,
                            data: value
                        )
                    )
                )
            )
        )

        try #require(message.type == .channelVoice1)
        let decodedMessage = MidiMessage.decode(message)
        #expect(decodedMessage == expectedMessages.first!)
    }

    @Test("Decode Program Change") func testDecodeProgramChange() async throws {
        let dummy: UInt8 = 0x00
        let channel: UInt8 = 0x05
        let program: UInt8 = 0x22
        let expectedMessages = [
            Localized.midiMessageProgramChange(channel, program)
        ]

        let packets = Data([dummy, dummy, 0xC0 | channel, program])
        let decodedMessages = MidiMessage.decode(packets)
        #expect(decodedMessages == expectedMessages)

        let message = MIDIUniversalMessage(
            type: .channelVoice1,
            group: 0,
            reserved: (0, 0, 0),
            .init(
                channelVoice1: .init(
                    status: .programChange,
                    channel: channel,
                    reserved: (0, 0, 0),
                    .init(program: program)
                )
            )
        )

        try #require(message.type == .channelVoice1)
        let decodedMessage = MidiMessage.decode(message)
        #expect(decodedMessage == expectedMessages.first!)
    }

    @Test("Decode Channel Pressure") func testDecodeChannelPressure()
        async throws
    {
        let dummy: UInt8 = 0x00
        let channel: UInt8 = 0x05
        let pressure: UInt8 = 0x22
        let expectedMessages = [
            Localized.midiMessageChannelPressure(channel, pressure)
        ]

        let packets = Data([dummy, dummy, 0xD0 | channel, pressure])
        let decodedMessages = MidiMessage.decode(packets)
        #expect(decodedMessages == expectedMessages)

        let message = MIDIUniversalMessage(
            type: .channelVoice1,
            group: 0,
            reserved: (0, 0, 0),
            .init(
                channelVoice1: .init(
                    status: .channelPressure,
                    channel: channel,
                    reserved: (0, 0, 0),
                    .init(channelPressure: pressure)
                )
            )
        )

        try #require(message.type == .channelVoice1)
        let decodedMessage = MidiMessage.decode(message)
        #expect(decodedMessage == expectedMessages.first!)
    }

    @Test("Decode Pitch Bend") func testDecodePitchBend() async throws {
        let dummy: UInt8 = 0x00
        let channel: UInt8 = 0x05
        let msb: UInt8 = 0x22
        let lsb: UInt8 = 0x79
        let bend: UInt16 = UInt16(msb) << 7 | UInt16(lsb)
        let expectedMessages = [
            Localized.midiMessagePitchBend(channel, bend)
        ]

        let packets = Data([dummy, dummy, 0xE0 | channel, msb, lsb])
        let decodedMessages = MidiMessage.decode(packets)
        #expect(decodedMessages == expectedMessages)

        let message = MIDIUniversalMessage(
            type: .channelVoice1,
            group: 0,
            reserved: (0, 0, 0),
            .init(
                channelVoice1: .init(
                    status: .pitchBend,
                    channel: channel,
                    reserved: (0, 0, 0),
                    .init(pitchBend: bend)
                )
            )
        )

        try #require(message.type == .channelVoice1)
        let decodedMessage = MidiMessage.decode(message)
        #expect(decodedMessage == expectedMessages.first!)
    }

    @Test("Decode SysEx") func testDecodeSysEx() async throws {
        let dummy: UInt8 = 0x00
        let channel: UInt8 = 0x05
        let array: [UInt8] = [0x22, 0x79, 0x07, 0x33, 0x12, 0x71]
        var tuple: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (
            0, 0, 0, 0, 0, 0
        )
        withUnsafeMutablePointer(to: &tuple) { (dst) -> Void in
            memcpy(dst, array, array.count)
        }

        var sequence = "0xF" + String(channel, radix: 16, uppercase: true)
        array[0..<5].forEach {
            let text = String($0, radix: 16, uppercase: true)
            sequence += ", 0x" + (text.count == 1 ? "0" : "") + text
        }
        sequence += ", ..."
        let expectedMessages = [
            Localized.midiMessageSystemExclusive(sequence)
        ]

        let packets = Data([dummy, dummy, 0xF0 | channel] + array)
        let decodedMessages = MidiMessage.decode(packets)
        #expect(decodedMessages == expectedMessages)

        let message = MIDIUniversalMessage(
            type: .sysEx,
            group: 0,
            reserved: (0, 0, 0),
            .init(
                sysEx: .init(
                    status: .start,
                    channel: channel,
                    data: tuple,
                    reserved: 0
                )
            )
        )

        try #require(message.type == .sysEx)
        let decodedMessage = MidiMessage.decode(message)
        #expect(decodedMessage == expectedMessages.first!)
    }

    @Test("Encode") func testEncode() async throws {
        let stampMSB: UInt8 = 0x34
        let stampLSB: UInt8 = 0x19
        let stamp: UInt64 = (UInt64(stampMSB) << 7) + UInt64(stampLSB)
        let channel: UInt8 = 0x09
        let note: UInt8 = 0x3C
        let velocity: UInt8 = 0x43
        let message1 = MIDI1UPNoteOn(1, channel, note, velocity)
        let message2 = MIDI1UPNoteOff(1, channel, note, velocity)
        let expectedData = [
            Data([
                0x80 | stampMSB, 0x80 | stampLSB, 0x90 | channel, note,
                velocity,
            ]),
            Data([
                0x80 | stampMSB, 0x80 | stampLSB, 0x80 | channel, note,
                velocity,
            ]),
        ]
        #expect(
            MidiMessage.encode([message1, message2], elapsedTime: stamp)
                == expectedData
        )
    }

}
