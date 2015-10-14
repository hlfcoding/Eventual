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
    
    func testValidateEmptyEvent() {
        // Given:
        let event = EKEvent(eventStore: self.eventManager.store)
        do {
            // When:
            try self.eventManager.validateEvent(event)
            // Then:
            XCTFail("Should throw error.")
        } catch let error as NSError {
            XCTAssertEqual(error.userInfo[NSLocalizedFailureReasonErrorKey] as? String, "Event title is required.",
                "Includes correct validation error.")
            XCTAssertEqual(error.code, ErrorCode.InvalidObject.rawValue,
                "Uses correct error code.")
            XCTAssertNotNil(error.userInfo[NSLocalizedDescriptionKey],
                "Includes main description.")
            XCTAssertNotNil(error.userInfo[NSLocalizedRecoverySuggestionErrorKey],
                "Includes recovery suggestion.")
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
