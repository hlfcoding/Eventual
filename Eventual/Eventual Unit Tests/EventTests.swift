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
        // When:
        event.prepare()
        // Then:
        XCTAssertTrue(event.allDay, "Sets to all-day by default.")
        XCTAssertEqual(event.endDate, event.startDate, "EventKit auto-adjusts endDate per allDay.")
    }

    func testPrepareCustomDurationEvent() {
        // Given:
        let event = TestEvent()
        event.startDate = NSDate().dayDate.hourDateFromAddingHours(1)
        // When:
        event.prepare()
        // Then:
        XCTAssertFalse(event.allDay, "Sets off all-day if time units are not 0.")
        XCTAssertEqual(event.endDate, event.startDate.hourDateFromAddingHours(1), "Sets duration to 1 hour.")
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
            try event.validate()
            // Then:
        } catch {
            XCTFail("Should not throw error.")
        }
    }

}
