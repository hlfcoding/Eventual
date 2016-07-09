//
//  DayViewCellRenderingTests.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

class DayViewCellRenderingTests: XCTestCase {

    class TestDayViewCell: NSObject, DayViewCellRenderable {
        var dayText: String?
        var numberOfEvents: Int?

        func renderDayText(value: String) { self.spy.renderDayTextCalledWith = value }
        func renderIsToday(value: Bool) { self.spy.renderIsTodayCalledWith = value }
        func renderNumberOfEvents(value: Int) { self.spy.renderNumberOfEventsCalledWith = value }

        typealias Spy = (
            renderDayTextCalledWith: String?,
            renderIsTodayCalledWith: Bool?,
            renderNumberOfEventsCalledWith: Int?
        )
        static func createSpy() -> Spy { return (nil, nil, nil) }
        var spy: Spy = TestDayViewCell.createSpy()
    }

    var cell: TestDayViewCell!
    var dayDate: NSDate!
    var dayEvents: DayEvents { return [TestEvent(identifier: "E-1", startDate: self.dayDate)] }

    var spy: TestDayViewCell.Spy! {
        get { return self.cell.spy }
        set { self.cell.spy = newValue }
    }

    override func setUp() {
        super.setUp()
        self.cell = TestDayViewCell()
        self.dayDate = today
    }

    func testRenderingDayTextAndNumberOfEvents() {
        DayViewCell.renderCell(self.cell, fromDayEvents: self.dayEvents, dayDate: self.dayDate)
        let dayText = NSDateFormatter.dayFormatter.stringFromDate(self.dayDate)
        XCTAssertEqual(self.spy.renderDayTextCalledWith, dayText, "Renders initially.")
        XCTAssertEqual(self.spy.renderNumberOfEventsCalledWith, self.dayEvents.count, "Renders initially.")
        self.spy = TestDayViewCell.createSpy()

        DayViewCell.renderCell(self.cell, fromDayEvents: self.dayEvents, dayDate: self.dayDate)
        XCTAssertNil(self.spy.renderDayTextCalledWith, "Avoids unneeded re-render.")
        XCTAssertNil(self.spy.renderNumberOfEventsCalledWith, "Avoids unneeded re-render.")
    }

    func testRenderingIsToday() {
        DayViewCell.renderCell(self.cell, fromDayEvents: self.dayEvents, dayDate: self.dayDate)
        XCTAssertEqual(self.spy.renderIsTodayCalledWith, true, "Renders correctly.")
        self.spy = TestDayViewCell.createSpy()

        self.dayDate = tomorrow
        DayViewCell.renderCell(self.cell, fromDayEvents: self.dayEvents, dayDate: self.dayDate)
        XCTAssertEqual(self.spy.renderIsTodayCalledWith, false, "Renders correctly.")
    }

}
