//
//  EventScreenTests.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class EventScreenTests: XCTestCase {

    var dayLabel: XCUIElement { return app.staticTexts[a(.EventDate)] }
    var dayMenu: XCUIElement { return app.scrollViews[a(.EventScreenTitle)] }
    var dayPicker: XCUIElement { return app.datePickers[a(.PickDate)] }
    var descriptionView: XCUIElement { return app.textViews[a(.EventDescription)] }
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

    func testTogglingDayPicker() {
        toNewEventScreenFromMonthsScreen()

        dayLabel.tap()
        XCTAssertTrue(laterItem.hittable, "Selects Later item.")
        XCTAssertTrue(dayPicker.hittable, "Shows Day picker.")
        XCTAssertFalse(dayLabel.hittable, "Hides Day label.")

        laterItem.tap()
        XCTAssertFalse(dayPicker.hittable, "Toggles Day picker.")
        XCTAssertTrue(dayLabel.hittable, "Toggles Day label.")

        laterItem.tap()
        XCTAssertTrue(dayPicker.hittable, "Toggles Day picker.")
        XCTAssertFalse(dayLabel.hittable, "Toggles Day label.")

        laterItem.tap()
        dayLabel.tap()
        XCTAssertTrue(dayPicker.hittable, "Shows Day picker.")
        XCTAssertFalse(dayLabel.hittable, "Hides Day label.")

        descriptionView.tap()
        XCTAssertFalse(dayPicker.hittable, "Hides Day picker.")
   }

    func testTogglingTimePicker() {
        toNewEventScreenFromMonthsScreen()

        eventItem.tap()
        XCTAssertTrue(timePicker.hittable, "Toggles Time picker.")
        XCTAssertFalse(dayLabel.hittable, "Hides Day label.")

        eventItem.tap()
        XCTAssertFalse(timePicker.hittable, "Toggles Time picker.")
        XCTAssertTrue(dayLabel.hittable, "Shows Day label.")

        dayLabel.tap()
        eventItem.tap()
        laterItem.tap()
        XCTAssertFalse(timePicker.hittable, "Hides Time picker.")
        XCTAssertTrue(dayPicker.hittable, "Shows Day picker.")

        laterItem.tap()
        XCTAssertTrue(timePicker.hittable, "Shows Time picker.")
        XCTAssertFalse(dayPicker.hittable, "Hides Day picker.")

        laterItem.tap()
        eventItem.tap()
        dayMenu.swipeRight()
        eventItem.tap()
        XCTAssertFalse(dayPicker.hittable, "Day picker should not re-focus.")
    }

}
