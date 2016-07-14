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
        self.continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it
        // happens for each test method.
        self.app = XCUIApplication()
        self.app.launch()
        self.collectionView = self.app.collectionViews[a(.DayEvents)]
    }

    func navigateToDayScreen() {
        let firstCell = self.app.cells[self.firstDayCellIdentifier()]
        self.waitForElement(firstCell)
        firstCell.tap()
    }

    func testNavigatingToFirstEvent() {
        self.navigateToDayScreen()

        let firstCell = self.app.cells[a(.FormatEventCell, 0)]
        self.waitForElement(firstCell)
        // NOTE: This requires an editable event.
        firstCell.tap()

        self.waitForElement(self.app.navigationBars[a(.EventScreenTitle)])
        XCTAssert(self.app.textViews[a(.EventDescription)].hittable)
    }

    func testTapBackgroundToAddEvent() {
        self.navigateToDayScreen()

        let background = self.collectionView.otherElements[a(.TappableBackground)]
        self.waitForElement(background)
        background.tap()

        self.waitForElement(self.app.navigationBars[a(.EventScreenTitle)])
        XCTAssert(self.app.textViews[a(.EventDescription)].hittable)
    }

}
