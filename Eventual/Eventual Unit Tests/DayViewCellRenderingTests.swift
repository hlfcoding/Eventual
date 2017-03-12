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
        var dayDate: Date?
        var monthDate: Date?
        var numberOfEvents: Int?

        var isRecurringEvents: Bool {
            return false
        }

        func renderAccessibilityValue(_ value: Any?) {
            spy.renderAccessibilityValueCalled = true
        }

        func render(dayText value: Date) {
            spy.renderDayTextCalledWith = value
        }

        func render(isToday value: Bool) {
            spy.renderIsTodayCalledWith = value
        }

        func render(numberOfEvents value: Int) {
            spy.renderNumberOfEventsCalledWith = value
        }

        func setUpAccessibility(at indexPath: IndexPath) {}

        typealias Spy = (
            renderAccessibilityValueCalled: Bool,
            renderDayTextCalledWith: Date?,
            renderIsTodayCalledWith: Bool?,
            renderNumberOfEventsCalledWith: Int?
        )

        static func createSpy() -> Spy {
            return (false, nil, nil, nil)
        }

        var spy: Spy = TestDayViewCell.createSpy()
    }

    var cell: TestDayViewCell!
    var dayDate: Date!
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
        dayDate = Date().dayDate
    }

    func testRenderingDayTextAndNumberOfEvents() {
        DayViewCell.render(cell: cell, fromDayEvents: dayEvents, dayDate: dayDate)
        XCTAssertEqual(spy.renderDayTextCalledWith, dayDate, "Renders initially.")
        XCTAssertEqual(spy.renderNumberOfEventsCalledWith, dayEvents.count, "Renders initially.")
        XCTAssertTrue(spy.renderAccessibilityValueCalled, "Renders initially.")
        spy = TestDayViewCell.createSpy()

        DayViewCell.render(cell: cell, fromDayEvents: dayEvents, dayDate: dayDate)
        XCTAssertNil(spy.renderDayTextCalledWith, "Avoids unneeded re-render.")
        XCTAssertNil(spy.renderNumberOfEventsCalledWith, "Avoids unneeded re-render.")
        XCTAssertFalse(spy.renderAccessibilityValueCalled, "Avoids unneeded re-render.")
    }

    func testRenderingIsToday() {
        DayViewCell.render(cell: cell, fromDayEvents: dayEvents, dayDate: dayDate)
        XCTAssertEqual(spy.renderIsTodayCalledWith, true, "Renders correctly.")
        spy = TestDayViewCell.createSpy()

        dayDate = tomorrow
        DayViewCell.render(cell: cell, fromDayEvents: dayEvents, dayDate: dayDate)
        XCTAssertEqual(spy.renderIsTodayCalledWith, false, "Renders correctly.")
    }

}
