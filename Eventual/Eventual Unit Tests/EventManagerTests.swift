//
//  EventManagerTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class EventManagerTests: XCTestCase {

    lazy var tomorrowEvents: [TestEvent] = [
        TestEvent(identifier: "Tomorrow-0", startDate: tomorrow),
        TestEvent(identifier: "Tomorrow-1", startDate: tomorrow),
    ]
    lazy var anotherMonthEvents: [TestEvent] = [
        TestEvent(identifier: "Another-Month-0", startDate: anotherMonth),
        TestEvent(identifier: "Another-Month-1", startDate: anotherMonth),
    ]
    lazy var events: [TestEvent] = self.tomorrowEvents + self.anotherMonthEvents

    var manager: EventManager!
    var managerEvents: [TestEvent] {
        guard let events = manager.events as? [TestEvent] else { preconditionFailure() }
        return events
    }

    override func setUp() {
        super.setUp()
        manager = EventManager()
    }

    // MARK: - Saving

    func testPrepareBasicAllDayEvent() {
        // Given:
        let event = TestEvent()
        // When:
        manager.prepareEvent(event)
        // Then:
        XCTAssertTrue(event.allDay, "Sets to all-day by default.")
        XCTAssertEqual(event.endDate, event.startDate, "EventKit auto-adjusts endDate per allDay.")
    }

    func testPrepareCustomDurationEvent() {
        // Given:
        let event = TestEvent()
        event.startDate = NSDate().dayDate.hourDateFromAddingHours(1)
        // When:
        manager.prepareEvent(event)
        // Then:
        XCTAssertFalse(event.allDay, "Sets off all-day if time units are not 0.")
        XCTAssertEqual(event.endDate, event.startDate.hourDateFromAddingHours(1), "Sets duration to 1 hour.")
    }

    func testAddEvent() {
        // Given:
        manager = EventManager(events: events)
        let event = TestEvent(identifier: "New-1", startDate: tomorrow.hourDateFromAddingHours(1))
        do {
            // When:
            try manager.addEvent(event)
            let newEvents = managerEvents
            // Then:
            XCTAssertEqual(newEvents.count, events.count + 1, "Adds to array.")
            XCTAssertTrue(newEvents.contains(event), "Adds to array.")
            XCTAssertEqual(newEvents.indexOf(event), tomorrowEvents.count, "Keeps array in ascending order.")
        } catch {
            XCTFail("Should not throw error.")
        }
    }

    func testAddExistingEvent() {
        // Given:
        let event = TestEvent(identifier: "Tomorrow-0", startDate: tomorrow)
        manager = EventManager(events: [event])
        do {
            // When:
            try manager.addEvent(event)
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
        manager = EventManager(events: events)
        let event = TestEvent(identifier: "Tomorrow-0", startDate: tomorrow)
        do {
            // When:
            try manager.replaceEvent(event)
            var newEvents = managerEvents
            // Then:
            XCTAssertEqual(newEvents.count, events.count, "Replaces the object.")
            XCTAssertTrue(newEvents.contains(event), "Replaces the object.")
            XCTAssertEqual(newEvents.indexOf(event), 1, "Keeps array in ascending order.")
            // Given:
            manager = EventManager(events: events)
            // When:
            try manager.replaceEvent(event, atIndex: 0)
            newEvents = managerEvents
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
        let event = TestEvent(identifier: "New-1", startDate: tomorrow)
        do {
            // When:
            try manager.replaceEvent(event)
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
            try manager.validateEvent(event)
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
            try manager.validateEvent(event)
            // Then:
        } catch {
            XCTFail("Should not throw error.")
        }
    }

}
