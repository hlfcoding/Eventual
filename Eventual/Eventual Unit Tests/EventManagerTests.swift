//
//  EventManagerTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

class EventManagerTests: XCTestCase {

    lazy var tomorrowEvents: [TestEvent] = [
        TestEvent(identifier: "Tomorrow-0", startDate: tomorrow),
        TestEvent(identifier: "Tomorrow-1", startDate: tomorrow)
    ]
    lazy var anotherMonthEvents: [TestEvent] = [
        TestEvent(identifier: "Another-Month-0", startDate: anotherMonth),
        TestEvent(identifier: "Another-Month-1", startDate: anotherMonth)
    ]
    lazy var events: [TestEvent] = self.tomorrowEvents + self.anotherMonthEvents

    var manager: EventManager!
    override func setUp() {
        super.setUp()
        self.manager = EventManager()
    }

    // MARK: - Saving

    func testPrepareBasicAllDayEvent() {
        // Given:
        let event = TestEvent()
        // When:
        self.manager.prepareEvent(event)
        // Then:
        XCTAssertTrue(event.allDay, "Sets to all-day by default.")
        XCTAssertEqual(event.endDate, event.startDate, "EventKit auto-adjusts endDate per allDay.")
    }

    func testPrepareCustomDurationEvent() {
        // Given:
        let event = TestEvent()
        event.startDate = NSDate().dayDate.hourDateFromAddingHours(1)
        // When:
        self.manager.prepareEvent(event)
        // Then:
        XCTAssertFalse(event.allDay, "Sets off all-day if time units are not 0.")
        XCTAssertEqual(event.endDate, event.startDate.hourDateFromAddingHours(1), "Sets duration to 1 hour.")
    }

    func testAddEvent() {
        // Given:
        self.manager = EventManager(events: events)
        let event = TestEvent(identifier: "New-1", startDate: tomorrow.hourDateFromAddingHours(1))
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
        let event = TestEvent(identifier: "Tomorrow-0", startDate: tomorrow)
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
        let event = TestEvent(identifier: "Tomorrow-0", startDate: tomorrow)
        do {
            // When:
            try self.manager.replaceEvent(event)
            var newEvents = self.manager.events as! [TestEvent]
            // Then:
            XCTAssertEqual(newEvents.count, self.events.count, "Replaces the object.")
            XCTAssertTrue(newEvents.contains(event), "Replaces the object.")
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
        let event = TestEvent(identifier: "New-1", startDate: tomorrow)
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
        let event = TestEvent()
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
        let event = TestEvent()
        event.title = "My Event"
        do {
            // When:
            try self.manager.validateEvent(event)
            // Then:
        } catch {
            XCTFail("Should not throw error.")
        }
    }

}
