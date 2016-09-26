//
//  EventScreenTests.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class EventScreenTests: XCTestCase {

    var dayLabel: XCUIElement { return app.buttons[a(.eventDate)] }
    var dayMenu: XCUIElement { return app.scrollViews[a(.eventScreenTitle)] }
    var dayPicker: XCUIElement { return app.datePickers[a(.pickDate)] }
    var descriptionView: XCUIElement { return app.textViews[a(.eventDescription)] }
    var laterItem: XCUIElement { return dayMenu.buttons[a(.formatDayOption, "Later")] }
    var timeItem: XCUIElement { return app.toolbars.buttons[a(.eventTime)] }
    var timePicker: XCUIElement { return app.datePickers[a(.pickTime)] }

    override func setUp() {
        super.setUp()
        setUpUITest()
    }

    func toNewEventScreenFromMonthsScreen() {
        toDayScreenFromMonthsScreen()
        tapBackground(of: app.collectionViews[a(.dayEvents)])
        waitForEventScreen()
    }

    func testTogglingDayPicker() {
        toNewEventScreenFromMonthsScreen()

        dayLabel.tap()
        XCTAssertTrue(laterItem.isHittable, "Selects Later item.")
        XCTAssertTrue(dayPicker.isHittable, "Shows Day picker.")
        XCTAssertFalse(dayLabel.isHittable, "Hides Day label.")

        laterItem.tap()
        XCTAssertFalse(dayPicker.isHittable, "Toggles Day picker.")
        XCTAssertTrue(dayLabel.isHittable, "Toggles Day label.")

        laterItem.tap()
        XCTAssertTrue(dayPicker.isHittable, "Toggles Day picker.")
        XCTAssertFalse(dayLabel.isHittable, "Toggles Day label.")

        laterItem.tap()
        dayLabel.tap()
        XCTAssertTrue(dayPicker.isHittable, "Shows Day picker.")
        XCTAssertFalse(dayLabel.isHittable, "Hides Day label.")

        descriptionView.tap()
        XCTAssertFalse(dayPicker.isHittable, "Hides Day picker.")

        laterItem.tap()
        descriptionView.tap()
        dayMenu.swipeRight()
        XCTAssertFalse(dayPicker.isHittable, "Hides Day picker.")
    }

    func testTogglingTimePicker() {
        toNewEventScreenFromMonthsScreen()

        timeItem.tap()
        XCTAssertTrue(timePicker.isHittable, "Toggles Time picker.")
        XCTAssertFalse(dayLabel.isHittable, "Hides Day label.")

        timeItem.tap()
        XCTAssertFalse(timePicker.isHittable, "Toggles Time picker.")
        XCTAssertTrue(dayLabel.isHittable, "Shows Day label.")

        dayLabel.tap()
        timeItem.tap()
        laterItem.tap()
        XCTAssertFalse(timePicker.isHittable, "Hides Time picker.")
        XCTAssertTrue(dayPicker.isHittable, "Shows Day picker.")

        laterItem.tap()
        XCTAssertTrue(timePicker.isHittable, "Shows Time picker.")
        XCTAssertFalse(dayPicker.isHittable, "Hides Day picker.")

        laterItem.tap()
        timeItem.tap()
        dayMenu.swipeRight()
        timeItem.tap()
        XCTAssertFalse(dayPicker.isHittable, "Day picker should not re-focus.")

        dayLabel.tap()
        timeItem.tap()
        dayMenu.swipeRight()
        XCTAssertTrue(timePicker.isHittable, "Time picker stays open.")
    }

}
