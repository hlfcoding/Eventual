//
//  EventDataSourcesTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class EventDataSourcesTests: XCTestCase {

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

    override func setUp() {
        super.setUp()
        manager = EventManager()
    }

    func testAddEvent() {
    }

    func testAddExistingEvent() {
    }

    func testReplaceEvent() {
    }

    func testReplaceNonexistingEvent() {
    }

}
