//
//  MonthsScreenTests.swift
//  Eventual UI Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class MonthsScreenTests: XCTestCase {

    var collectionView: XCUIElement { return app.collectionViews[a(.MonthDays)] }

    override func setUp() {
        super.setUp()
        setUpUITest()
    }

    func testNavigatingToFirstDay() {
        XCTAssertTrue(collectionView.exists)
        toDayScreenFromMonthsScreen()
    }

    func testTappingTitleToScrollToTop() {

        func assertIsAtTop() {
            waitForElement(firstDayCell)
            XCTAssertTrue(firstDayCell.hittable)
        }

        waitForMonthsScreen()
        collectionView.swipeUp()
        app.scrollViews[a(.MonthsScreenTitle)].tap()
        assertIsAtTop()
    }

    // TODO: Bug #23161435 -- mitigated by tweaking section inset.
    func pending_testTapBackgroundToAddEvent() {
        tapBackgroundOfCollectionView(collectionView)
    }

}
