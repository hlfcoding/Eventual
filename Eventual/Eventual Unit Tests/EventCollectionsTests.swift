//
//  EventCollectionsTests.swift
//  Eventual
//
//  Created by Peng Wang on 2/17/16.
//  Copyright © 2016 Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

class EventCollectionsTests: XCTestCase {

    lazy var tomorrowEvents: [TestEvent] = [
        TestEvent(identifier: "Tomorrow-0", startDate: tomorrow),
        TestEvent(identifier: "Tomorrow-1", startDate: tomorrow)
    ]
    lazy var anotherMonthEvents: [TestEvent] = [
        TestEvent(identifier: "Another-Month-0", startDate: anotherMonth),
        TestEvent(identifier: "Another-Month-1", startDate: anotherMonth)
    ]
    lazy var events: [TestEvent] = self.tomorrowEvents + self.anotherMonthEvents

    override func setUp() {
        super.setUp()
    }
    
    func testArrangingEventsByMonthsAndDays() {
        // When:
        let monthsEvents = MonthsEvents(events: self.events)
        var monthEvents: MonthEvents?
        // Then:
        XCTAssertEqual(monthsEvents.months.count, 2, "Months should be separated and populated correctly.")
        XCTAssertEqual(monthsEvents.months.count, monthsEvents.events.count, "Month start-dates should correspond to event collections.")

        monthEvents = monthsEvents.events[0] as? MonthEvents
        XCTAssertEqual(monthEvents?.days.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(monthEvents?.events.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(monthEvents?.days[0] as? NSDate, tomorrow, "Day start-date should be correct.")
        XCTAssertEqual((monthEvents?.events[0] as? [TestEvent])?.count, self.tomorrowEvents.count, "Events should be grouped by day correctly.")

        monthEvents = monthsEvents.events[1] as? MonthEvents
        XCTAssertEqual(monthEvents?.days.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(monthEvents?.events.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(monthEvents?.days[0] as? NSDate, anotherMonth, "Day start-date should be correct.")
        XCTAssertEqual((monthEvents?.events[0] as? [TestEvent])?.count, self.anotherMonthEvents.count, "Events should be grouped by day correctly.")
    }

    func testGettingEventsForMonthOfDate() {
        // Given:
        let monthsEvents = MonthsEvents(events: self.events)
        // When:
        let currentMonthEvents = monthsEvents.eventsForMonthOfDate(tomorrow.monthDate)
        // Then:
        XCTAssertEqual(currentMonthEvents?.events.count, 1, "Finds and returns correct month's events.")
        XCTAssertEqual(currentMonthEvents?.events[0] as? DayEvents, self.tomorrowEvents, "Finds and returns correct month's events.")
    }

    func testGettingEventsForDayOfDate() {
        // Given:
        let monthsEvents = MonthsEvents(events: self.events)
        // When:
        let tomorrowEvents = monthsEvents.eventsForDayOfDate(tomorrow)
        let anotherMonthEvents = monthsEvents.eventsForDayOfDate(anotherMonth)
        // Then:
        XCTAssertEqual(tomorrowEvents, self.tomorrowEvents, "Finds and returns correct day's events.")
        XCTAssertEqual(anotherMonthEvents, self.anotherMonthEvents, "Finds and returns correct day's events.")
    }


    func testGettingEventsForDayAtIndexPath() {
        // Given:
        let monthsEvents = MonthsEvents(events: self.events)
        // When:
        var anotherMonthEvents = monthsEvents.eventsForDayAtIndexPath(NSIndexPath(forItem: 0, inSection: 1))
        // Then:
        XCTAssertEqual(anotherMonthEvents, self.anotherMonthEvents, "Finds and returns correct day's events.")
        // When:
        anotherMonthEvents = monthsEvents.eventsForDayAtIndexPath(NSIndexPath(forItem: 0, inSection: 2))
        // Then:
        XCTAssertNil(anotherMonthEvents, "Returns nil if index out of bounds.")
    }

    func testGettingDayDatesForIndexPath() {
        // Given:
        let monthsEvents = MonthsEvents(events: self.events)
        // When:
        var anotherMonthDays = monthsEvents.daysForMonthAtIndex(1)
        var anotherMonthDay = monthsEvents.dayAtIndexPath(NSIndexPath(forItem: 0, inSection: 1))
        // Then:
        XCTAssertEqual(anotherMonthDays, [anotherMonth], "Finds and returns correct days.")
        XCTAssertEqual(anotherMonthDay, anotherMonth, "Finds and returns correct day.")
        // When:
        anotherMonthDays = monthsEvents.daysForMonthAtIndex(2)
        anotherMonthDay = monthsEvents.dayAtIndexPath(NSIndexPath(forItem: 0, inSection: 2))
        // Then:
        XCTAssertNil(anotherMonthDays, "Returns nil if index out of bounds.")
        XCTAssertNil(anotherMonthDay, "Returns nil if index out of bounds.")
    }

}
