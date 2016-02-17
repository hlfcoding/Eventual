//
//  EventManagerTests.swift
//  Eventual
//
//  Created by Peng Wang on 10/14/15.
//  Copyright (c) 2015-2016 Eventual App. All rights reserved.
//

import XCTest
import EventKit
@testable import Eventual

class EventManagerTests: XCTestCase {

    static let store = EKEventStore()

    class TestEvent: Event {

        private var testIdentifier: String!
        override var identifier: String { return testIdentifier }

        init(identifier: String, startDate: NSDate) {
            super.init(entity: EKEvent(eventStore: EventManagerTests.store))

            self.testIdentifier = identifier
            self.startDate = startDate
        }
    }

    lazy var tomorrow = NSDate().dayDateFromAddingDays(1)
    lazy var anotherMonth = NSDate().dayDateFromAddingDays(100)
    lazy var tomorrowEvents: [TestEvent] = [
        TestEvent(identifier: "Tomorrow-0", startDate: self.tomorrow),
        TestEvent(identifier: "Tomorrow-1", startDate: self.tomorrow)
    ]
    lazy var anotherMonthEvents: [TestEvent] = [
        TestEvent(identifier: "Another-Month-0", startDate: self.anotherMonth),
        TestEvent(identifier: "Another-Month-1", startDate: self.anotherMonth)
    ]
    lazy var events: [TestEvent] = self.tomorrowEvents + self.anotherMonthEvents

    var manager: EventManager!
    var store: EKEventStore!
    override func setUp() {
        super.setUp()
        self.manager = EventManager()
        self.store = self.manager.store
    }

    // MARK: - Saving

    func testPrepareBasicAllDayEvent() {
        // Given:
        let event = Event(entity: EKEvent(eventStore: self.store))
        // When:
        self.manager.prepareEvent(event)
        // Then:
        XCTAssertTrue(event.allDay, "Sets to all-day by default.")
        XCTAssertEqual(event.endDate, event.startDate, "EventKit auto-adjusts endDate per allDay.")
    }

    func testPrepareCustomDurationEvent() {
        // Given:
        let event = Event(entity: EKEvent(eventStore: self.store))
        event.startDate = NSDate().dayDate!.hourDateFromAddingHours(1)
        // When:
        self.manager.prepareEvent(event)
        // Then:
        XCTAssertFalse(event.allDay, "Sets off all-day if time units are not 0.")
        XCTAssertEqual(event.endDate, event.startDate.hourDateFromAddingHours(1), "Sets duration to 1 hour.")
    }

    func testAddEvent() {
        // Given:
        self.manager = EventManager(events: events)
        let event = TestEvent(identifier: "New-1", startDate: self.tomorrow.hourDateFromAddingHours(1))
        do {
            // When:
            try self.manager.addEvent(event)
            let newEvents = self.manager.events as! [TestEvent]
            // Then:
            XCTAssertEqual(newEvents.count, self.events.count + 1, "Adds to array.")
            XCTAssertTrue(newEvents.contains(event), "Adds to array.")
            XCTAssertEqual(newEvents.indexOf(event), self.tomorrowEvents.count, "Keeps array in ascending order.")
        } catch {
            XCTFail("Should not throw error.")
        }
    }

    func testAddExistingEvent() {
        // Given:
        let event = TestEvent(identifier: "Tomorrow-0", startDate: self.tomorrow)
        self.manager = EventManager(events: [event])
        do {
            // When:
            try self.manager.addEvent(event)
            // Then:
            XCTFail("Should throw error.")
        } catch EventManagerError.EventAlreadyExists(let index) {
            XCTAssertEqual(index, 0, "Thrown error comes with the existing index.")
        } catch {
            XCTFail("Wrong error thrown.")
        }
    }

    func testReplaceEvent() {
        // Given:
        self.manager = EventManager(events: self.events)
        let event = TestEvent(identifier: "Tomorrow-0", startDate: self.tomorrow)
        do {
            // When:
            try self.manager.replaceEvent(event)
            var newEvents = self.manager.events as! [TestEvent]
            // Then:
            XCTAssertEqual(newEvents.count, self.events.count, "Replaces the object.")
            XCTAssertTrue(newEvents.contains(event), "Replaces the object.")
            // FIXME: This could be a small defect.
            XCTAssertEqual(newEvents.indexOf(event), 1, "Keeps array in ascending order.")
            // Given:
            self.manager = EventManager(events: self.events)
            // When:
            try self.manager.replaceEvent(event, atIndex: 0)
            newEvents = self.manager.events as! [TestEvent]
            // Then:
            XCTAssertEqual(newEvents.count, self.events.count, "Replaces the object more quickly.")
            XCTAssertTrue(newEvents.contains(event), "Replaces the object more quickly.")
            XCTAssertEqual(newEvents.indexOf(event), 1, "Keeps array in ascending order.")
        } catch {
            XCTFail("Should not throw error.")
        }
    }

    func testReplaceNonexistingEvent() {
        // Given:
        let event = TestEvent(identifier: "New-1", startDate: self.tomorrow)
        do {
            // When:
            try self.manager.replaceEvent(event)
            // Then:
            XCTFail("Should throw error.")
        } catch EventManagerError.EventNotFound {
        } catch {
            XCTFail("Wrong error thrown.")
        }
    }

    // MARK: - Validation

    func testValidateEmptyEvent() {
        // Given:
        let event = Event(entity: EKEvent(eventStore: self.store))
        do {
            // When:
            try self.manager.validateEvent(event)
            // Then:
            XCTFail("Should throw error.")
        } catch let error as NSError {
            XCTAssertEqual(error.userInfo[NSLocalizedFailureReasonErrorKey] as? String, "Event title is required.", "Includes correct validation error.")
            XCTAssertEqual(error.code, ErrorCode.InvalidObject.rawValue, "Uses correct error code.")
            XCTAssertNotNil(error.userInfo[NSLocalizedDescriptionKey], "Includes main description.")
            XCTAssertNotNil(error.userInfo[NSLocalizedRecoverySuggestionErrorKey], "Includes recovery suggestion.")
        } catch {
            XCTFail("Wrong error thrown.")
        }
    }

    func testValidateFilledEvent() {
        // Given:
        let event = Event(entity: EKEvent(eventStore: self.store))
        event.title = "My Event"
        do {
            // When:
            try self.manager.validateEvent(event)
            // Then:
        } catch {
            XCTFail("Should not throw error.")
        }
    }

    // MARK: - Arrangement

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
        XCTAssertEqual(monthEvents?.days[0] as? NSDate, self.tomorrow, "Day start-date should be correct.")
        XCTAssertEqual((monthEvents?.events[0] as? [TestEvent])?.count, self.tomorrowEvents.count, "Events should be grouped by day correctly.")

        monthEvents = monthsEvents.events[1] as? MonthEvents
        XCTAssertEqual(monthEvents?.days.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(monthEvents?.events.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(monthEvents?.days[0] as? NSDate, self.anotherMonth, "Day start-date should be correct.")
        XCTAssertEqual((monthEvents?.events[0] as? [TestEvent])?.count, self.anotherMonthEvents.count, "Events should be grouped by day correctly.")
    }

    func testGettingEventsForDayOfDate() {
        // Given:
        let monthsEvents = MonthsEvents(events: self.events)
        // When:
        let tomorrowEvents = monthsEvents.eventsForDayOfDate(self.tomorrow)
        let anotherMonthEvents = monthsEvents.eventsForDayOfDate(self.anotherMonth)
        // Then:
        XCTAssertEqual(tomorrowEvents, self.tomorrowEvents, "Finds and returns correct day's events.")
        XCTAssertEqual(anotherMonthEvents, self.anotherMonthEvents, "Finds and returns correct day's events.")
    }

}
