# Welcome to SwiftMidiCentral
I'm a newcomer to Swift and SwiftUI. After reading various project and trying to write a first App to connect to either MIDI USB, Bluetooth peripheral and centrals, it occured that supporting several MIDI transport protocols under one hood was far lest trivial than initialy anticipated.
This project has been triggered to investigate:
- Automatic connection to Bluetooth peripherals without having to use the midimittr App. This is achieved through a direct CoreBluetooth central.
- Direct CoreBluetooth replacement for the CABTMIDILocalPeripheralViewController which exhibits a weird hectic behavior -- namely the arrangement of the fields change randomly.
- A tentative usage of class derivation and protocols to allow previews and testing.
# v1.0.0
The first attempt separates Bluetooth and USB transport layers. The former is entirely handled through CoreBluetooth, while the latter uses CoreMIDI. It appeared that CoreMIDI readily takes over messaging from remote centrals subscribint to the local MIDI peripheral. Usage of MIDIBluetoothDriverActivateAllConnections has been tried to pass MIDI message exchange with remote Bluetooth peripherals to CoreMIDI as suggested in [MIDI Bluetooth | Apple Developer Documentation](https://developer.apple.com/documentation/coremidi/midi-bluetooth).
# v2.0.0
In this second implementation, usage of CoreBluetooth has been limited to advertizing the local peripheral and to subscribing automatically to remote peripherals.
The CABTMIDICentralViewController is used to connect CoreMIDI to subscribed remote peripherals.
# Request for comments/suggestions
This project is most likely using unacademic use of Swift and SwiftUI. It also lacks much testing. It would be much appreciated if experienced Swift/SwiftUI programmers would share their insight as too how this code should evolve to better form.
Many thanks in advance,
François
