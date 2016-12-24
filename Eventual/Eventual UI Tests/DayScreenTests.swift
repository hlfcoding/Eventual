//
//  DayScreenTests.swift
//  Eventual UI Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class DayScreenTests: XCTestCase {

    var collectionView: XCUIElement { return app.collectionViews[a(.dayEvents)] }

    override func setUp() {
        super.setUp()
        setUpUITest()
    }

    func assertDismissal() {
        wait(for: collectionView)
        XCTAssertTrue(collectionView.isHittable, "Dismisses back to Day screen.")
    }

    func testNavigatingToFirstEvent() {
        toEventScreenFromMonthsScreen()
        app.navigationBars[a(.eventScreenTitle)].buttons[a(.navigationBack)].tap()
        assertDismissal()
    }

    func testTapBackgroundToAddEvent() {
        toDayScreenFromMonthsScreen()
        tapBackground(of: collectionView)
        waitForEventScreen()

        app.textViews[a(.eventDescription)].typeText("Some event description.")
        app.toolbars.buttons[a(.saveEvent)].tap()
        assertDismissal()
    }

}
