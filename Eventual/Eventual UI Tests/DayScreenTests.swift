//
//  DayScreenTests.swift
//  Eventual UI Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class DayScreenTests: XCTestCase {

    var collectionView: XCUIElement { return app.collectionViews[a(.DayEvents)] }

    override func setUp() {
        super.setUp()
        setUpUITest()
    }

    func testNavigatingToFirstEvent() {
        toEventScreenFromMonthsScreen()
    }

    func testTapBackgroundToAddEvent() {

        func assertDismissal() {
            waitForElement(collectionView)
            XCTAssert(collectionView.hittable)
        }

        toDayScreenFromMonthsScreen()
        tapBackgroundOfCollectionView(collectionView)
        waitForEventScreen()

        app.textViews[a(.EventDescription)].typeText("Some event description.")
        app.toolbars.buttons[a(.SaveEvent)].tap()
        assertDismissal()
    }

}
