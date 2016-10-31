//
//  EventTests.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class EventTests: XCTestCase {

    // MARK: - Defaults

    func testPrepareBasicAllDayEvent() {
        // Given:
        let event = TestEvent()
        event.startDate = Date().dayDate
        // When:
        event.prepare()
        // Then:
        XCTAssertTrue(event.isAllDay, "Sets to all-day by default.")
        XCTAssertEqual(event.endDate, event.startDate, "EventKit auto-adjusts endDate per allDay.")
    }

    func testPrepareCustomDurationEvent() {
        // Given:
        let event = TestEvent()
        event.startDate = Date().dayDate.hourDate(byAddingHours: 1)
        // When:
        event.prepare()
        // Then:
        XCTAssertFalse(event.isAllDay, "Sets off all-day if time units are not 0.")
        XCTAssertEqual(event.endDate, event.startDate.hourDate(byAddingHours: 1), "Sets duration to 1 hour.")
    }

    // MARK: - Validation

    func testValidateEmptyEvent() {
        // Given:
        let event = TestEvent()
        do {
            // When:
            try event.validate()
            // Then:
            XCTFail("Should throw error.")
        } catch let error as LocalizedError {
            XCTAssertEqual(error.failureReason, "Event title is required.", "Includes correct validation error.")
            XCTAssertNotNil(error.errorDescription, "Includes main description.")
            XCTAssertNotNil(error.recoverySuggestion, "Includes recovery suggestion.")
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
            try event.validate()
            // Then:
        } catch {
            XCTFail("Should not throw error.")
        }
    }

}
