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
        var dayDate: NSDate?
        var numberOfEvents: Int?

        func renderAccessibilityValue(values: (Int, NSDate)) {
            spy.renderAccessibilityValueCalledWith = values
        }

        func renderDayText(value: NSDate) {
            spy.renderDayTextCalledWith = value
        }

        func renderIsToday(value: Bool) {
            spy.renderIsTodayCalledWith = value
        }

        func renderNumberOfEvents(value: Int) {
            spy.renderNumberOfEventsCalledWith = value
        }

        typealias Spy = (
            renderAccessibilityValueCalledWith: (Int, NSDate)?,
            renderDayTextCalledWith: NSDate?,
            renderIsTodayCalledWith: Bool?,
            renderNumberOfEventsCalledWith: Int?
        )

        static func createSpy() -> Spy {
            return (nil, nil, nil, nil)
        }

        var spy: Spy = TestDayViewCell.createSpy()
    }

    var cell: TestDayViewCell!
    var dayDate: NSDate!
    var dayEvents: DayEvents { return [TestEvent(identifier: "E-1", startDate: dayDate)] }

    var spy: TestDayViewCell.Spy! {
        get {
            return cell.spy
        }
        set {
            cell.spy = newValue
        }
    }

    override func setUp() {
        super.setUp()
        cell = TestDayViewCell()
        dayDate = NSDate().dayDate
    }

    func testRenderingDayTextAndNumberOfEvents() {
        DayViewCell.renderCell(cell, fromDayEvents: dayEvents, dayDate: dayDate)
        XCTAssertEqual(spy.renderDayTextCalledWith, dayDate, "Renders initially.")
        XCTAssertEqual(spy.renderNumberOfEventsCalledWith, dayEvents.count, "Renders initially.")
        XCTAssertEqual(spy.renderAccessibilityValueCalledWith!.0, dayEvents.count, "Renders initially.")
        XCTAssertEqual(spy.renderAccessibilityValueCalledWith!.1, dayDate, "Renders initially.")
        spy = TestDayViewCell.createSpy()

        DayViewCell.renderCell(cell, fromDayEvents: dayEvents, dayDate: dayDate)
        XCTAssertNil(spy.renderDayTextCalledWith, "Avoids unneeded re-render.")
        XCTAssertNil(spy.renderNumberOfEventsCalledWith, "Avoids unneeded re-render.")
        XCTAssertNil(spy.renderAccessibilityValueCalledWith, "Avoids unneeded re-render.")
    }

    func testRenderingIsToday() {
        DayViewCell.renderCell(cell, fromDayEvents: dayEvents, dayDate: dayDate)
        XCTAssertEqual(spy.renderIsTodayCalledWith, true, "Renders correctly.")
        spy = TestDayViewCell.createSpy()

        dayDate = tomorrow
        DayViewCell.renderCell(cell, fromDayEvents: dayEvents, dayDate: dayDate)
        XCTAssertEqual(spy.renderIsTodayCalledWith, false, "Renders correctly.")
    }

}
