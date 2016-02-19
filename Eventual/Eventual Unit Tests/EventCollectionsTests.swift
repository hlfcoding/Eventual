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
        let monthsEvents = MonthsEvents(events: self.events)
        var monthEvents: MonthEvents?
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
        let monthsEvents = MonthsEvents(events: self.events)
        let currentMonthEvents = monthsEvents.eventsForMonthOfDate(tomorrow.monthDate)
        XCTAssertEqual(currentMonthEvents?.events.count, 1, "Finds and returns correct month's events.")
        XCTAssertEqual(currentMonthEvents?.events[0] as? DayEvents, self.tomorrowEvents, "Finds and returns correct month's events.")
    }

    func testGettingEventsForDayOfDate() {
        let monthsEvents = MonthsEvents(events: self.events)
        let tomorrowEvents = monthsEvents.eventsForDayOfDate(tomorrow)
        let anotherMonthEvents = monthsEvents.eventsForDayOfDate(anotherMonth)
        XCTAssertEqual(tomorrowEvents, self.tomorrowEvents, "Finds and returns correct day's events.")
        XCTAssertEqual(anotherMonthEvents, self.anotherMonthEvents, "Finds and returns correct day's events.")
    }


    func testGettingEventsForDayAtIndexPath() {
        let monthsEvents = MonthsEvents(events: self.events)
        var anotherMonthEvents = monthsEvents.eventsForDayAtIndexPath(NSIndexPath(forItem: 0, inSection: 1))
        XCTAssertEqual(anotherMonthEvents, self.anotherMonthEvents, "Finds and returns correct day's events.")

        anotherMonthEvents = monthsEvents.eventsForDayAtIndexPath(NSIndexPath(forItem: 0, inSection: 2))
        XCTAssertNil(anotherMonthEvents, "Returns nil if index out of bounds.")
    }

    func testGettingDayDatesForIndexPath() {
        let monthsEvents = MonthsEvents(events: self.events)
        var anotherMonthDays = monthsEvents.daysForMonthAtIndex(1)
        var anotherMonthDay = monthsEvents.dayAtIndexPath(NSIndexPath(forItem: 0, inSection: 1))
        XCTAssertEqual(anotherMonthDays, [anotherMonth], "Finds and returns correct days.")
        XCTAssertEqual(anotherMonthDay, anotherMonth, "Finds and returns correct day.")

        anotherMonthDays = monthsEvents.daysForMonthAtIndex(2)
        anotherMonthDay = monthsEvents.dayAtIndexPath(NSIndexPath(forItem: 0, inSection: 2))
        XCTAssertNil(anotherMonthDays, "Returns nil if index out of bounds.")
        XCTAssertNil(anotherMonthDay, "Returns nil if index out of bounds.")
    }

    func testGettingIndexPathOfDayForDate() {
        let monthsEvents = MonthsEvents(events: self.events)
        let anotherMonthIndexPath = monthsEvents.indexPathForDayOfDate(anotherMonth)
        XCTAssertEqual(anotherMonthIndexPath, NSIndexPath(forItem: 0, inSection: 1), "Finds day and returns its index path.")

        let todayIndexPath = monthsEvents.indexPathForDayOfDate(NSDate())
        XCTAssertNil(todayIndexPath, "Returns nil if indices are out of bounds")
    }

}
