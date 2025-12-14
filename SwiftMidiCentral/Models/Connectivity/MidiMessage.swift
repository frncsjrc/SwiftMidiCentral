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

        let bytes = [UInt8](packet)
        var index = 0
        while index < bytes.count - 1 {
            if bytes.count < index + 4 {
                Logger.connectivity.error("Invalid MIDI packet: \(packet)")
                index = bytes.count
            } else {
                let status = bytes[index + 2] & 0xF0
                switch status {
                case 0x80:
                    let channel = bytes[index + 2] & 0x0F
                    let key = bytes[index + 3]
                    let velocity = bytes[index + 4]
                    messages.append(
                        Localized.midiMessageNoteOff(channel, key, velocity)
                    )
                    index += 5
                case 0x90:
                    let channel = bytes[index + 2] & 0x0F
                    let key = bytes[index + 3]
                    let velocity = bytes[index + 4]
                    messages.append(
                        Localized.midiMessageNoteOn(channel, key, velocity)
                    )
                    index += 5
                case 0xA0:
                    let channel = bytes[index + 2] & 0x0F
                    let key = bytes[index + 3]
                    let pressure = bytes[index + 4]
                    messages.append(
                        Localized.midiMessagePolyPressure(
                            channel,
                            key,
                            pressure
                        )
                    )
                    index += 5
                case 0xB0:
                    let channel = bytes[index + 2] & 0x0F
                    let control = bytes[index + 3]
                    let value = bytes[index + 4]
                    messages.append(
                        Localized.midiMessageControlChange(
                            channel,
                            control,
                            value
                        )
                    )
                    index += 5
                case 0xC0:
                    let channel = bytes[index + 2] & 0x0F
                    let program = bytes[index + 3]
                    messages.append(
                        Localized.midiMessageProgramChange(channel, program)
                    )
                    index += 4
                case 0xD0:
                    let channel = bytes[index + 2] & 0x0F
                    let pressure = bytes[index + 3]
                    messages.append(
                        Localized.midiMessageChannelPressure(channel, pressure)
                    )
                    index += 4
                case 0xE0:
                    let channel = bytes[index + 2] & 0x0F
                    let bend: UInt16 =
                        UInt16(bytes[index + 3]) << 7 | UInt16(bytes[index + 4])
                    messages.append(
                        Localized.midiMessagePitchBend(channel, bend)
                    )
                    index += 5
                case 0xF0:
                    var sequence = ""
                    bytes[index + 2..<index + 8].forEach({
                        let text = String($0, radix: 16, uppercase: true)
                        sequence +=
                            (sequence.isEmpty ? "0x" : ", 0x")
                            + (text.count == 1 ? "0" : "") + text
                    })
                    sequence += bytes.count >= 8 ? ", ..." : ""
                    messages.append(
                        Localized.midiMessageSystemExclusive(sequence)
                    )
                    index = bytes.count
                default:
                    Logger.connectivity.error(
                        "Invalid MIDI packet status \(status) at index \(index + 2) in \(packet)"
                    )
                    index = bytes.count
                }
            }
        }

        return messages
    }

    static func decode(_ packet: MIDIUniversalMessage) -> String? {
        switch packet.type {
        case .sysEx:
            let data = packet.sysEx.data
            var sequence = "0xF" + String(packet.sysEx.channel, radix: 16, uppercase: true)
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

        let timeStamp = elapsedTime & 0x1FFF
        let timeStampMSB: UInt8 = 0x80 | UInt8(timeStamp >> 7)
        let timeStampLSB: UInt8 = 0x80 | UInt8(timeStamp & 0x7F)

        packets.forEach { packet in
            //            let data0 = UInt8((packet >> 24) & 0xFF)
            let data1 = UInt8((packet >> 16) & 0xFF)
            let data2 = UInt8((packet >> 8) & 0xFF)
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
        }

        return encodedPackets
    }
}
