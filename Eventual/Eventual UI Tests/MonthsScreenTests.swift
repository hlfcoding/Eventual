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
    var navigationBar: XCUIElement!

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
        self.navigationBar = self.app.navigationBars[a(.MonthsScreenTitle)]
        self.firstCell = self.app.cells[self.firstDayCellIdentifier()]
    }

    func testMonthsCollectionViewExistence() {
        XCTAssert(self.collectionView.exists)
    }

    func testNavigatingToFirstDay() {
        self.waitForElement(self.firstCell) { (_) in
            self.firstCell.tap()
            XCTAssert(self.app.collectionViews[Label.DayEvents.rawValue].exists)
        }
    }

    func testTapTitleToScrollToTop() {
        let title = self.navigationBar.scrollViews[a(.MonthsScreenTitle)]
        self.waitForElement(self.firstCell) { (_) in
            self.collectionView.swipeUp()
            title.tap()
            // Verify by manual observation.
            // TODO: Can't figure out yet, but get title text before scroll to match with after tap.
        }
    }

    // TODO: Bug #23161435 -- mitigated by tweaking section inset.
    func testTapBackgroundToAddEvent() {
        let background = self.collectionView.otherElements[a(.TappableBackground)]
        self.waitForElement(background) { (_) in
            background.tap()
            // Verify by manual observation.
            // TODO: Somehow nothing on Event screen can be found.
            // self.waitForElement(self.app.otherElements[Label.EventForm.rawValue])
        }
    }

}
