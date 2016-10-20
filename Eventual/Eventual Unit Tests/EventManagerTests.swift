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
        return manager.events as! [TestEvent]
    }

    override func setUp() {
        super.setUp()
        manager = EventManager()
    }

    // MARK: - Saving

    func testAddEvent() {
        // Given:
        manager = EventManager(events: events)
        let event = TestEvent(identifier: "New-1", startDate: tomorrow.hourDate(byAddingHours: 1))
        do {
            // When:
            try manager.add(event: event)
            let newEvents = managerEvents
            // Then:
            XCTAssertEqual(newEvents.count, events.count + 1, "Adds to array.")
            XCTAssertTrue(newEvents.contains(event), "Adds to array.")
            XCTAssertEqual(newEvents.index(of: event), tomorrowEvents.count, "Keeps array in ascending order.")
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
            try manager.add(event: event)
            // Then:
            XCTFail("Should throw error.")
        } catch EventManagerError.eventAlreadyExists(let index) {
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
            try manager.replace(event: event)
            var newEvents = managerEvents
            // Then:
            XCTAssertEqual(newEvents.count, events.count, "Replaces the object.")
            XCTAssertTrue(newEvents.contains(event), "Replaces the object.")
            XCTAssertEqual(newEvents.index(of: event), 1, "Keeps array in ascending order.")
            // Given:
            manager = EventManager(events: events)
            // When:
            try manager.replace(event: event, at: 0)
            newEvents = managerEvents
            // Then:
            XCTAssertEqual(newEvents.count, events.count, "Replaces the object more quickly.")
            XCTAssertTrue(newEvents.contains(event), "Replaces the object more quickly.")
            XCTAssertEqual(newEvents.index(of: event), 1, "Keeps array in ascending order.")
        } catch {
            XCTFail("Should not throw error.")
        }
    }

    func testReplaceNonexistingEvent() {
        // Given:
        let event = TestEvent(identifier: "New-1", startDate: tomorrow)
        do {
            // When:
            try manager.replace(event: event)
            // Then:
            XCTFail("Should throw error.")
        } catch EventManagerError.eventNotFound {
        } catch {
            XCTFail("Wrong error thrown.")
        }
    }

}
