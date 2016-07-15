//
//  DayScreenTests.swift
//  Eventual UI Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class DayScreenTests: XCTestCase {

    var app: XCUIApplication!
    var collectionView: XCUIElement!

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
        collectionView = app.collectionViews[a(.DayEvents)]
    }

    func navigateToDayScreen() {
        let firstCell = app.cells[firstDayCellIdentifier()]
        waitForElement(firstCell)
        firstCell.tap()
    }

    func testNavigatingToFirstEvent() {
        navigateToDayScreen()

        let firstCell = app.cells[a(.FormatEventCell, 0)]
        waitForElement(firstCell)
        // NOTE: This requires an editable event.
        firstCell.tap()

        waitForElement(app.navigationBars[a(.EventScreenTitle)])
        XCTAssert(app.textViews[a(.EventDescription)].hittable)
    }

    func testTapBackgroundToAddEvent() {
        navigateToDayScreen()

        let background = collectionView.otherElements[a(.TappableBackground)]
        waitForElement(background)
        background.tap()

        waitForElement(app.navigationBars[a(.EventScreenTitle)])
        XCTAssert(app.textViews[a(.EventDescription)].hittable)
    }

}
