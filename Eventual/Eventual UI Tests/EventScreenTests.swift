//
//  EventScreenTests.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class EventScreenTests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        // Auto-generated.
        XCUIDevice.sharedDevice().orientation = .Portrait
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it
        // happens for each test method.
        app = XCUIApplication()
        app.launch()
    }

    func toNewEventScreenFromMonthsScreen() {
        let firstCell = app.cells[firstDayCellIdentifier()]
        waitForElement(firstCell)
        firstCell.tap()

        let background = app.collectionViews[a(.DayEvents)].otherElements[a(.TappableBackground)]
        waitForElement(background)
        background.tap()

        waitForElement(app.navigationBars[a(.EventScreenTitle)])
    }

    func testTappingDayLabel() {
        toNewEventScreenFromMonthsScreen()

        app.staticTexts[a(.EventDate)].tap()

        XCTAssert(app.navigationBars[a(.EventScreenTitle)].buttons[a(.FormatDayOption, "Later")].exists, "Selects Later item.")
        XCTAssert(app.datePickers[a(.PickDate)].hittable, "Toggles Day picker.")
    }

}
