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
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it
        // happens for each test method.
        app = XCUIApplication()
        app.launch()
        collectionView = app.collectionViews[a(.MonthDays)]
        firstCell = app.cells[firstDayCellIdentifier()]
    }

    func testNavigatingToFirstDay() {
        XCTAssert(collectionView.exists)

        waitForElement(firstCell)
        firstCell.tap()

        waitForElement(app.collectionViews[a(.DayEvents)])
    }

    func testTappingTitleToScrollToTop() {
        waitForElement(firstCell)
        collectionView.swipeUp()
        app.scrollViews[a(.MonthsScreenTitle)].tap()

        waitForElement(firstCell)
        XCTAssert(firstCell.hittable)
    }

    // TODO: Bug #23161435 -- mitigated by tweaking section inset.
    func pending_testTapBackgroundToAddEvent() {
        let background = collectionView.otherElements[a(.TappableBackground)]
        waitForElement(background)
        background.tap()

    }

}
