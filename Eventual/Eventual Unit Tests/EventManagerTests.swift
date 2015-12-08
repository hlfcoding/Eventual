//
//  EventManagerTests.swift
//  Eventual
//
//  Created by Peng Wang on 10/14/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import XCTest
import EventKit
@testable import Eventual

class EventManagerTests: XCTestCase {

    // MARK: - Mocks

    class TestEvent: NSObject {
        var identifier: String
        var startDate: NSDate
        init(identifier: String, startDate: NSDate) {
            self.identifier = identifier
            self.startDate = startDate
            super.init()
        }
        override func valueForKey(key: String) -> AnyObject? {
            switch key {
            case "eventIdentifier": return self.identifier
            case "startDate": return self.startDate
            default: return super.valueForKey(key)
            }
        }
        func compareStartDateWithEvent(other: TestEvent) -> NSComparisonResult {
            return self.startDate.compare(other.startDate)
        }
    }

    let tomorrow = NSDate().dayDateFromAddingDays(1)
    let anotherMonth = NSDate().dayDateFromAddingDays(100)

    lazy var tomorrowEvents: [TestEvent] = { return Array(0..<2).map { index in
        TestEvent(identifier: "Tomorrow-\(index)", startDate: self.tomorrow)
    }}()
    lazy var anotherMonthEvents: [TestEvent] = { return Array(0..<2).map {
        index in TestEvent(identifier: "Another-Month-\(index)", startDate: self.anotherMonth)
    }}()

    lazy var someTestEvents: [TestEvent] = { return self.tomorrowEvents + self.anotherMonthEvents }()

    // MARK: - Common

    var eventManager: EventManager!

    override func setUp() {
        super.setUp()
        self.eventManager = EventManager()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Saving

    func testPrepareBasicAllDayEvent() {
        // Given:
        let event = EKEvent(eventStore: self.eventManager.store)
        // When:
        self.eventManager.prepareEvent(event)
        // Then:
        XCTAssertTrue(event.allDay, "Sets to all-day by default.")
        XCTAssertEqual(event.endDate, event.startDate, "EventKit auto-adjusts endDate per allDay.")
    }

    func testPrepareCustomDurationEvent() {
        // Given:
        let event = EKEvent(eventStore: self.eventManager.store)
        event.startDate = NSDate().hourDateFromAddingHours(1)
        // When:
        self.eventManager.prepareEvent(event)
        // Then:
        XCTAssertFalse(event.allDay, "Sets off all-day if time units are not 0.")
        XCTAssertEqual(event.endDate, event.startDate.hourDateFromAddingHours(1), "Sets duration to 1 hour.")
    }

    func testAddEvent() {
        // Given:
        let events = self.someTestEvents
        let event = TestEvent(identifier: "New-1", startDate: tomorrow.hourDateFromAddingHours(1))
        let newEvents: [TestEvent]
        do {
            // When:
            try newEvents = self.eventManager.addEvent(event as NSObject, toEvents: events as [NSObject]) as! [TestEvent]
            // Then:
            XCTAssertEqual(newEvents.count, events.count + 1, "Adds to array.")
            XCTAssertTrue(newEvents.contains(event), "Adds to array.")
            XCTAssertEqual(newEvents.indexOf(event), self.tomorrowEvents.count, "Keeps array in ascending order.")
        } catch {
            XCTFail("Should not throw error.")
        }
    }

    func testAddExistingEvent() {
        // Given:
        let events = self.someTestEvents
        let event = TestEvent(identifier: "Tomorrow-0", startDate: tomorrow)
        do {
            // When:
            try self.eventManager.addEvent(event as NSObject, toEvents: events as [NSObject]) as! [TestEvent]
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
        var events = self.someTestEvents
        let event = TestEvent(identifier: "Tomorrow-0", startDate: tomorrow)
        var newEvents: [TestEvent]
        do {
            // When:
            try newEvents = self.eventManager.replaceEvent(event as NSObject, inEvents: events as [NSObject]) as! [TestEvent]
            // Then:
            XCTAssertEqual(newEvents.count, events.count, "Replaces the object.")
            XCTAssertTrue(newEvents.contains(event), "Replaces the object.")
            // FIXME: This could be a small defect.
            XCTAssertEqual(newEvents.indexOf(event), 1, "Keeps array in ascending order.")
            // When:
            events = self.someTestEvents
            try newEvents = self.eventManager.replaceEvent(event as NSObject, inEvents: events as [NSObject], atIndex: 0) as! [TestEvent]
            // Then:
            XCTAssertEqual(newEvents.count, events.count, "Replaces the object more quickly.")
            XCTAssertTrue(newEvents.contains(event), "Replaces the object more quickly.")
            XCTAssertEqual(newEvents.indexOf(event), 1, "Keeps array in ascending order.")
        } catch {
            XCTFail("Should not throw error.")
        }
    }

    func testReplaceNonexistingEvent() {
        // Given:
        let events = self.someTestEvents
        let event = TestEvent(identifier: "New-1", startDate: tomorrow)
        do {
            // When:
            try self.eventManager.replaceEvent(event as NSObject, inEvents: events as [NSObject]) as! [TestEvent]
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
        let event = EKEvent(eventStore: self.eventManager.store)
        do {
            // When:
            try self.eventManager.validateEvent(event)
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
        let event = EKEvent(eventStore: self.eventManager.store)
        event.title = "My Event"
        do {
            // When:
            try self.eventManager.validateEvent(event)
            // Then:
        } catch {
            XCTFail("Should not throw error.")
        }
    }

    // MARK: - Arrangement

    func testArrangeToEventsByMonthsAndDays() {
        // Given:
        let events = self.someTestEvents
        // When:
        let months = self.eventManager.arrangeToEventsByMonthsAndDays(events)
        var days: DateIndexedEventCollection?
        // Then:
        XCTAssertNotNil(months[DatesKey], "Has array of month start-dates as month identifiers.")
        XCTAssertNotNil(months[DaysKey], "Has array of arrays of hashes of day start-dates and day events.")
        XCTAssertEqual(months[DatesKey]?.count, 2, "Months should be separated and populated correctly.")
        XCTAssertEqual(months[DatesKey]?.count, months[DaysKey]?.count, "Month start-dates should correspond to event collections.")

        days = months[DaysKey]?[0] as? DateIndexedEventCollection
        XCTAssertNotNil(days?[DatesKey], "Has nested array of day start-states as day identifiers.")
        XCTAssertNotNil(days?[EventsKey], "Has nested array of day events.")
        XCTAssertEqual(days?[DatesKey]?.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(days?[EventsKey]?.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(days?[DatesKey]?[0] as? NSDate, self.tomorrow, "Day start-date should be correct.")
        XCTAssertEqual((days?[EventsKey]?[0] as? [TestEvent])?.count, self.tomorrowEvents.count, "Events should be grouped by day correctly.")

        days = months[DaysKey]?[1] as? DateIndexedEventCollection
        XCTAssertEqual(days?[DatesKey]?.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(days?[EventsKey]?.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(days?[DatesKey]?[0] as? NSDate, self.anotherMonth, "Day start-date should be correct.")
        XCTAssertEqual((days?[EventsKey]?[0] as? [TestEvent])?.count, self.anotherMonthEvents.count, "Events should be grouped by day correctly.")
    }

    func testEventsForDayDate() {
        // Given:
        let months = self.eventManager.arrangeToEventsByMonthsAndDays(self.someTestEvents)
        // When:
        let tomorrowEvents = self.eventManager.eventsForDayDate(self.tomorrow, months: months)
        let anotherMonthEvents = self.eventManager.eventsForDayDate(self.anotherMonth, months: months)
        // Then:
        XCTAssertEqual(tomorrowEvents, self.tomorrowEvents, "Finds and returns correct day's events.")
        XCTAssertEqual(anotherMonthEvents, self.anotherMonthEvents, "Finds and returns correct day's events.")
    }

}
