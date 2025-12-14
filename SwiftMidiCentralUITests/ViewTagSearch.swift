//
//  ViewTagSearch.swift
//  SwiftMidiCentralUITests
//
//  Created by François Jean Raymond CLÉMENT on 13/12/2025.
//

import XCTest

func getAppViewFromTag(_ tag: String) -> XCUIElement {
    XCUIApplication().descendants(matching: .any).matching(identifier: tag).element
}
