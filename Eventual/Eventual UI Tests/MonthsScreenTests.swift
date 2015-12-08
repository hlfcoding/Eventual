//
//  MonthsScreenTests.swift
//  Eventual UI Tests
//
//  Created by Peng Wang on 7/4/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import XCTest

class MonthsScreenTests: XCTestCase {

    var app: XCUIApplication!
    var collectionView: XCUIElement!
    var firstCell: XCUIElement!
    var navigationBar: XCUIElement!

    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        self.continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        self.app = XCUIApplication()
        self.app.launchArguments = ["WORK_AROUND_23161435"]
        self.app.launch()
        self.collectionView = self.app.collectionViews[Label.MonthDays.rawValue]
        self.firstCell = self.app.cells[NSString(format: Label.FormatDayCell.rawValue, 0, 0) as String]
        self.navigationBar = self.app.navigationBars[Label.MonthsScreenTitle.rawValue]
    }

    override func tearDown() {
        super.tearDown()
    }

    func testMonthsCollectionViewExistence() {
        XCTAssert(self.collectionView.exists)
    }

    func testNavigatingToFirstDay() {
        self.waitForElement(self.firstCell, timeout: nil) { (_) in
            self.firstCell.tap()
            XCTAssert(self.app.collectionViews[Label.DayEvents.rawValue].exists)
        }
    }

    func testTapTitleToScrollToTop() {
        let title = self.navigationBar.scrollViews[Label.MonthsScreenTitle.rawValue]
        self.waitForElement(self.firstCell, timeout: nil) { (_) in
            self.collectionView.swipeUp()
            title.tap()
            // Verify by manual observation.
            // TODO: Can't figure out yet, but get title text before scroll to match with after tap.
        }
    }

    // TODO: Bug #23161435 -- mitigated by tweaking section inset.
    func testTapBackgroundToAddEvent() {
        let background = self.collectionView.otherElements[Label.TappableBackground.rawValue]
        self.waitForElement(background, timeout: nil) { (_) in
            background.tap()
            // Verify by manual observation.
            // TODO: Somehow nothing on Event screen can be found.
            // self.waitForElement(self.app.otherElements[Label.EventForm.rawValue])
        }
    }

}
