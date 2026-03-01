//
//  MidiMessage.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 24/11/2025.
//

import CoreMIDI
import Foundation
import OSLog

struct MidiMessage {
    static func decode(_ packet: Data) -> [String] {
        var messages: [String] = []

        let oneByteStatusCodes: Set<UInt8> = [0xC0, 0xD0]
        let bytes = [UInt8](packet)
        var index = 1  // Drop first MSB stamp byte
        while index < bytes.count {
            // Skip LSB stamp byte
            while index + 1 < bytes.count, bytes[index + 1] >= 0x80 {
                index += 1
            }

            let status = bytes[index] & 0xF0
            let channel = bytes[index] & 0x0F
            index += 1

            if index + (oneByteStatusCodes.contains(status) ? 0 : 1)
                >= bytes.count
            {
                Logger.connectivity.debug("Truncated MIDI packet: \(packet)")
                break
            }

            switch status {
            case 0x80:
                while index + 1 < bytes.count,
                    bytes[index] < 0x80,
                    bytes[index + 1] < 0x80
                {
                    let key = bytes[index]
                    let velocity = bytes[index + 1]
                    messages.append(
                        Localized.midiMessageNoteOff(channel, key, velocity)
                    )
                    index += 2
                    if index + 2 < bytes.count,
                        bytes[index] >= 0x80,
                        bytes[index + 1] < 0x80,
                        bytes[index + 2] < 0x80
                    {
                        index += 1
                    }
                }
            case 0x90:
                while index + 1 < bytes.count,
                    bytes[index] < 0x80,
                    bytes[index + 1] < 0x80
                {
                    let key = bytes[index]
                    let velocity = bytes[index + 1]
                    messages.append(
                        Localized.midiMessageNoteOn(channel, key, velocity)
                    )
                    index += 2
                    if index + 2 < bytes.count,
                        bytes[index] >= 0x80,
                        bytes[index + 1] < 0x80,
                        bytes[index + 2] < 0x80
                    {
                        index += 1
                    }
                }
            case 0xA0:
                while index + 1 < bytes.count,
                    bytes[index] < 0x80,
                    bytes[index + 1] < 0x80
                {
                    let key = bytes[index]
                    let pressure = bytes[index + 1]
                    messages.append(
                        Localized.midiMessagePolyPressure(
                            channel,
                            key,
                            pressure
                        )
                    )
                    index += 2
                    if index + 2 < bytes.count,
                        bytes[index] >= 0x80,
                        bytes[index + 1] < 0x80,
                        bytes[index + 2] < 0x80
                    {
                        index += 1
                    }
                }
            case 0xB0:
                while index + 1 < bytes.count,
                    bytes[index] < 0x80,
                    bytes[index + 1] < 0x80
                {
                    let control = bytes[index]
                    let value = bytes[index + 1]
                    messages.append(
                        Localized.midiMessageControlChange(
                            channel,
                            control,
                            value
                        )
                    )
                    index += 2
                    if index + 2 < bytes.count,
                        bytes[index] >= 0x80,
                        bytes[index + 1] < 0x80,
                        bytes[index + 2] < 0x80
                    {
                        index += 1
                    }
                }
            case 0xC0:
                let program = bytes[index]
                messages.append(
                    Localized.midiMessageProgramChange(channel, program)
                )
                index += 1
            case 0xD0:
                let pressure = bytes[index]
                messages.append(
                    Localized.midiMessageChannelPressure(channel, pressure)
                )
                index += 1
            case 0xE0:
                while index + 1 < bytes.count,
                    bytes[index] < 0x80,
                    bytes[index + 1] < 0x80
                {
                    let bend: UInt16 =
                        UInt16(bytes[index]) << 7 | UInt16(bytes[index + 1])
                    messages.append(
                        Localized.midiMessagePitchBend(channel, bend)
                    )
                    index += 2
                    if index + 2 < bytes.count,
                        bytes[index] >= 0x80,
                        bytes[index + 1] < 0x80,
                        bytes[index + 2] < 0x80
                    {
                        index += 1
                    }
                }
            case 0xF0:
                var sequence = ""
                bytes[index..<index + 6].forEach({
                    let text = String($0, radix: 16, uppercase: true)
                    sequence +=
                        (sequence.isEmpty ? "0x" : ", 0x")
                        + (text.count == 1 ? "0" : "") + text
                })
                sequence += bytes.count >= 6 ? ", ..." : ""
                messages.append(
                    Localized.midiMessageSystemExclusive(sequence)
                )
                index = bytes.count
            default:
                Logger.connectivity.error(
                    "Invalid MIDI packet status \(status) at index \(index + 2) in \(packet)"
                )
                messages.append(Localized.midiMessageInvalidStatus)
                index = bytes.count
            }
        }

        return messages
    }

    static func decode(_ packet: MIDIUniversalMessage) -> String? {
        switch packet.type {
        case .sysEx:
            let data = packet.sysEx.data
            var sequence =
                "0xF" + String(packet.sysEx.channel, radix: 16, uppercase: true)
            [data.0, data.1, data.2, data.3, data.4].forEach {
                let text = String($0, radix: 16, uppercase: true)
                sequence += ", 0x" + (text.count == 1 ? "0" : "") + text
            }
            sequence += ", ..."
            return Localized.midiMessageSystemExclusive(sequence)
        case .channelVoice1:
            switch packet.channelVoice1.status {
            case .noteOn:
                let channel = packet.channelVoice1.channel
                let key = packet.channelVoice1.note.number
                let velocity = packet.channelVoice1.note.velocity
                return Localized.midiMessageNoteOn(channel, key, velocity)
            case .noteOff:
                let channel = packet.channelVoice1.channel
                let key = packet.channelVoice1.note.number
                let velocity = packet.channelVoice1.note.velocity
                return Localized.midiMessageNoteOff(channel, key, velocity)
            case .polyPressure:
                let channel = packet.channelVoice1.channel
                let key = packet.channelVoice1.polyPressure.noteNumber
                let pressure = packet.channelVoice1.polyPressure.pressure
                return Localized.midiMessagePolyPressure(
                    channel,
                    key,
                    pressure
                )
            case .controlChange:
                let channel = packet.channelVoice1.channel
                let control = packet.channelVoice1.controlChange.index
                let value = packet.channelVoice1.controlChange.data
                return Localized.midiMessageControlChange(
                    channel,
                    control,
                    value
                )
            case .channelPressure:
                let channel = packet.channelVoice1.channel
                let pressure = packet.channelVoice1.channelPressure
                return Localized.midiMessageChannelPressure(channel, pressure)
            case .pitchBend:
                let channel = packet.channelVoice1.channel
                let bend = packet.channelVoice1.pitchBend
                return Localized.midiMessagePitchBend(channel, bend)
            case .programChange:
                let channel = packet.channelVoice1.channel
                let program = packet.channelVoice1.program
                return Localized.midiMessageProgramChange(channel, program)
            default:
                return Localized.midiMessageUnknown
            }
        default:
            return nil
        }
    }

    static func encode(
        _ packets: [UInt32],
        maxSize: Int = 256,
        elapsedTime: UInt64 = clock_gettime_nsec_np(CLOCK_MONOTONIC)
    ) -> [Data] {
        var encodedPackets: [Data] = []

        var timeStamp = elapsedTime & 0x3FFF

        packets.forEach { packet in
            let timeStampMSB: UInt8 = 0x80 | UInt8((timeStamp >> 7) & 0x3F)
            let timeStampLSB: UInt8 = 0x80 | UInt8(timeStamp & 0x7F)
            let data1 = UInt8(packet >> 16 & 0xFF)
            let data2 = UInt8(packet >> 8 & 0xFF)
            let data3 = UInt8(packet & 0xFF)
            let status = data1 & 0xF0

            var encodedPacket = Data()
            encodedPacket.append(timeStampMSB)
            encodedPacket.append(timeStampLSB)
            encodedPacket.append(data1)
            encodedPacket.append(data2)
            if status < 0xC0 || status > 0xD0 {
                encodedPacket.append(data3)
            }

            encodedPackets.append(encodedPacket)
            timeStamp += 5
        }

        return encodedPackets
    }
}
