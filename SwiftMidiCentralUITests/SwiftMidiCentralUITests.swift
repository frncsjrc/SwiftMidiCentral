//
//  SwiftMidiCentralUITests.swift
//  SwiftMidiCentralUITests
//
//  Created by François Jean Raymond CLÉMENT on 21/11/2025.
//

import XCTest

//@testable import SwiftMidiCentral

final class SwiftMidiCentralUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        let existsPredicate = NSPredicate(format: "exists == true")
        // Use XCTAssert and related functions to verify your tests produce the correct results.
//        let _ = getAppViewFromTag(ViewTags.Buttons.scan)
        let scanButton = getAppViewFromTag("scanButton")
        expectation(for: existsPredicate, evaluatedWith: scanButton, handler: nil)
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
        XCTAssert(scanButton.exists)
        scanButton.tap()
//        app.pickerWheels.element.adjust(toPickerWheelValue: "Remote 3")
//        XCTAssert(app.pickerWheels.element.label == "Remote 3")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
