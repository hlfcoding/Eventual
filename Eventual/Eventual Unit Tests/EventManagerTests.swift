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

    func testArrangeToEventsByMonthsAndDays() {
        // Given:
        class TestEvent: NSObject {
            var startDate: NSDate
            init(startDate: NSDate) {
                self.startDate = startDate
                super.init()
            }
            private override func valueForKey(key: String) -> AnyObject? {
                switch key {
                    case "startDate": return self.startDate
                    default: return super.valueForKey(key)
                }
            }
        }
        // When:
        let tomorrow = NSDate().dayDateFromAddingDays(1)
        let anotherMonth = NSDate().dayDateFromAddingDays(100)
        let events = [
            TestEvent(startDate: tomorrow),
            TestEvent(startDate: tomorrow),
            TestEvent(startDate: anotherMonth),
            TestEvent(startDate: anotherMonth)
        ]
        let months = self.eventManager.arrangeToEventsByMonthsAndDays(events)
        var days: DateIndexedEventCollection?
        var daysDates: NSArray?
        var daysEvents: NSArray?
        // Then:
        let monthsDates = months[EntityCollectionDatesKey]
        let monthsDays = months[EntityCollectionDaysKey]
        XCTAssertNotNil(monthsDates, "Has array of month start-dates as month identifiers.")
        XCTAssertNotNil(monthsDays, "Has array of arrays of hashes of day start-dates and day events.")
        XCTAssertEqual(monthsDates?.count, 2, "Months should be separated and populated correctly.")
        XCTAssertEqual(monthsDates?.count, monthsDays?.count, "Month start-dates should correspond to event collections.")

        days = monthsDays?[0] as? DateIndexedEventCollection
        daysDates = days?[EntityCollectionDatesKey]
        daysEvents = days?[EntityCollectionEventsKey]
        XCTAssertNotNil(daysDates, "Has nested array of day start-states as day identifiers.")
        XCTAssertNotNil(daysEvents, "Has nested array of day events.")
        XCTAssertEqual(daysDates?.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(daysEvents?.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(daysDates?[0] as? NSDate, tomorrow, "Day start-date should be correct.")
        XCTAssertEqual((daysEvents?[0] as? [TestEvent])?.count, 2, "Events should be grouped by day correctly.")

        days = monthsDays?[1] as? DateIndexedEventCollection
        daysDates = days?[EntityCollectionDatesKey]
        daysEvents = days?[EntityCollectionEventsKey]
        XCTAssertEqual(daysDates?.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(daysEvents?.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(daysDates?[0] as? NSDate, anotherMonth, "Day start-date should be correct.")
        XCTAssertEqual((daysEvents?[0] as? [TestEvent])?.count, 2, "Events should be grouped by day correctly.")
    }

}
