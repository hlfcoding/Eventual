//
//  DateExtensionTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class DateExtensionTests: XCTestCase {

    lazy var calendar = Calendar.current
    lazy var midnight = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!

    func testDayDate() {
        let afterMidnight = calendar.date(bySettingHour: 1, minute: 1, second: 1, of: Date())!
        XCTAssertEqual(afterMidnight.dayDate, midnight, "Truncates units below day.")
    }

    func testHourDate() {
        let midnightAndChange = calendar.date(bySettingHour: 0, minute: 1, second: 1, of: Date())!
        XCTAssertEqual(midnightAndChange.hourDate, midnight, "Truncates units below hour.")
    }

    func testMonthDate() {

        let middleOfMonth = calendar.date(from: DateComponents(year: 2015, month: 1, day: 15, hour: 1, minute: 1, second: 1))!
        let startOfMonth = calendar.date(from: DateComponents(year: 2015, month: 1, day: 1))!
        XCTAssertEqual(middleOfMonth.monthDate, startOfMonth)
    }

    func testDayDateFromAddingDays() {
        let endOfMonth = calendar.date(from: DateComponents(year: 2015, month: 1, day: 31, hour: 23, minute: 59, second: 59))!
        let startOfNextMonth = calendar.date(from: DateComponents(year: 2015, month: 2, day: 1))!
        XCTAssertEqual(endOfMonth.dayDate(byAddingDays: 1), startOfNextMonth, "Carries over to month unit when needed.")
    }

    func testHourDateFromAddingHours() {
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: midnight)
        XCTAssertEqual(endOfToday.hourDate(byAddingHours: 1), tomorrow, "Carries over to day unit when needed.")
    }

    func testDateWithTime() {
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        XCTAssertEqual(endOfToday.date(withTime: midnight), midnight, "Wraps day unit when needed.")
    }

    func testHasCustomTime() {
        XCTAssertFalse(midnight.hasCustomTime)
        XCTAssertTrue(calendar.date(bySettingHour: 1, minute: 1, second: 1, of: Date())!.hasCustomTime)
        XCTAssertTrue(calendar.date(bySettingHour: 1, minute: 1, second: 0, of: Date())!.hasCustomTime)
        XCTAssertTrue(calendar.date(bySettingHour: 1, minute: 0, second: 0, of: Date())!.hasCustomTime)
    }

}
