//
//  MonthsScreenTests.swift
//  Eventual UI Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class MonthsScreenTests: XCTestCase {

    var app: XCUIApplication!
    var collectionView: XCUIElement!
    var firstCell: XCUIElement!

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
        self.collectionView = self.app.collectionViews[a(.MonthDays)]
        self.firstCell = self.app.cells[self.firstDayCellIdentifier()]
    }

    func testNavigatingToFirstDay() {
        XCTAssert(self.collectionView.exists)

        self.waitForElement(self.firstCell)
        self.firstCell.tap()

        self.waitForElement(self.app.collectionViews[a(.DayEvents)])
    }

    func testTappingTitleToScrollToTop() {
        self.waitForElement(self.firstCell)
        self.collectionView.swipeUp()
        self.app.scrollViews[a(.MonthsScreenTitle)].tap()

        self.waitForElement(self.firstCell)
        XCTAssert(self.firstCell.hittable)
    }

    // TODO: Bug #23161435 -- mitigated by tweaking section inset.
    func pending_testTapBackgroundToAddEvent() {
        let background = self.collectionView.otherElements[a(.TappableBackground)]
        self.waitForElement(background)
        background.tap()

        self.waitForElement(self.app.otherElements[a(.EventForm)])
    }

}
