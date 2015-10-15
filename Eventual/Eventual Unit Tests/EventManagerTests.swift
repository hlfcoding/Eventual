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

}
