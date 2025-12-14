//
//  SwiftMidiCentralLogger.swift
//  SwiftMidiCentral
//
//  Created by François Jean Raymond CLÉMENT on 21/11/2025.
//

import Foundation
import OSLog

extension Logger {
    // Set the overall subsystem identifier
    static var swiftMidiCentralSubsystem = Constants.rootIdentifier + ".log"

    // Define log categories
    static var connectivity: Logger {
        Logger(
            subsystem: swiftMidiCentralSubsystem,
            category: "Connectivity"
        )
    }
    static var viewCycle: Logger {
        Logger(
            subsystem: swiftMidiCentralSubsystem,
            category: "ViewCycle"
        )
    }
    static var analytics: Logger {
        Logger(
            subsystem: swiftMidiCentralSubsystem,
            category: "Analytics"
        )
    }

    // Define filter predicates
    static var southBridgeFilter: NSPredicate {
        NSPredicate(format: "subsystem == %@", swiftMidiCentralSubsystem)
    }
    static var connectivityFilter: NSPredicate {
        NSPredicate(
            format: "(subsystem == %@) && (category = %@)",
            swiftMidiCentralSubsystem,
            "Connectivity"
        )
    }
    static var viewCycleFilter: NSPredicate {
        NSPredicate(
            format: "(subsystem == %@) && (category = %@)",
            swiftMidiCentralSubsystem,
            "ViewCycle"
        )
    }
    static var analyticsFilter: NSPredicate {
        NSPredicate(
            format: "(subsystem == %@) && (category = %@)",
            swiftMidiCentralSubsystem,
            "Analytics"
        )
    }
}
