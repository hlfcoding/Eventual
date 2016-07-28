//
//  EventScreenTests.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class EventScreenTests: XCTestCase {

    override func setUp() {
        super.setUp()
        setUpUITest()
    }

    func toNewEventScreenFromMonthsScreen() {
        toDayScreenFromMonthsScreen()
        tapBackgroundOfCollectionView(app.collectionViews[a(.DayEvents)])
        waitForEventScreen()
    }

    func testTappingDayLabel() {
        toNewEventScreenFromMonthsScreen()

        app.staticTexts[a(.EventDate)].tap()

        let laterItem = app.navigationBars[a(.EventScreenTitle)].buttons[a(.FormatDayOption, "Later")]
        XCTAssert(laterItem.hittable, "Selects Later item.")
        XCTAssert(app.datePickers[a(.PickDate)].hittable, "Toggles Day picker.")
    }

    func testTogglingTimePicker() {
        toNewEventScreenFromMonthsScreen()

        let button = app.toolbars.buttons[a(.EventTime)]

        button.tap()
        XCTAssert(app.datePickers[a(.PickTime)].hittable, "Toggles Time picker.")

        button.tap()
        XCTAssertFalse(app.datePickers[a(.PickTime)].hittable, "Toggles Time picker.")
    }

}
