//
//  EventScreenTests.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class EventScreenTests: XCTestCase {

    var dayLabel: XCUIElement { return app.staticTexts[a(.EventDate)] }
    var dayPicker: XCUIElement { return app.datePickers[a(.PickDate)] }
    var eventItem: XCUIElement { return app.toolbars.buttons[a(.EventTime)] }
    var laterItem: XCUIElement { return app.navigationBars[a(.EventScreenTitle)].buttons[a(.FormatDayOption, "Later")] }
    var timePicker: XCUIElement { return app.datePickers[a(.PickTime)] }

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

        dayLabel.tap()

        XCTAssertTrue(laterItem.hittable, "Selects Later item.")
        XCTAssertTrue(dayPicker.hittable, "Shows Day picker.")
    }

    func testTogglingTimePicker() {
        toNewEventScreenFromMonthsScreen()

        eventItem.tap()
        XCTAssertTrue(timePicker.hittable, "Toggles Time picker.")

        eventItem.tap()
        XCTAssertFalse(timePicker.hittable, "Toggles Time picker.")

    }

}
