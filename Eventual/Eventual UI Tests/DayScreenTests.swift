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

    func assertDismissal() {
        waitForElement(collectionView)
        XCTAssertTrue(collectionView.hittable, "Dismisses back to Day screen.")
    }

    func testNavigatingToFirstEvent() {
        toEventScreenFromMonthsScreen()
        navigationBackButton(.EventScreenTitle).tap()
        assertDismissal()
    }

    func testTapBackgroundToAddEvent() {
        toDayScreenFromMonthsScreen()
        tapBackgroundOfCollectionView(collectionView)
        waitForEventScreen()

        app.textViews[a(.EventDescription)].typeText("Some event description.")
        app.toolbars.buttons[a(.SaveEvent)].tap()
        assertDismissal()
    }

}
