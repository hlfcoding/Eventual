//
//  NSDateExtensionTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

class NSDateExtensionTests: XCTestCase {

    lazy var calendar = NSCalendar.currentCalendar()
    lazy var midnight = NSCalendar.currentCalendar().dateBySettingHour(0, minute: 0, second: 0, ofDate: NSDate(), options: [])!

    func testDayDate() {
        let afterMidnight = calendar.dateBySettingHour(1, minute: 1, second: 1, ofDate: NSDate(), options: [])!
        XCTAssertEqual(afterMidnight.dayDate, midnight, "Truncates units below day.")
    }
    func testHourDate() {
        let midnightAndChange = calendar.dateBySettingHour(0, minute: 1, second: 1, ofDate: NSDate(), options: [])!
        XCTAssertEqual(midnightAndChange.hourDate, midnight, "Truncates units below hour.")
    }
    func testMonthDate() {
        let middleOfMonth = calendar.dateWithEra(1, year: 2015, month: 1, day: 15, hour: 1, minute: 1, second: 1, nanosecond: 0)!
        let startOfMonth = calendar.dateWithEra(1, year: 2015, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0)!
        XCTAssertEqual(middleOfMonth.monthDate, startOfMonth)
    }

    func testDayDateFromAddingDays() {
        let endOfMonth = calendar.dateWithEra(1, year: 2015, month: 1, day: 31, hour: 23, minute: 59, second: 59, nanosecond: 0)!
        let startOfNextMonth = calendar.dateWithEra(1, year: 2015, month: 2, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0)!
        XCTAssertEqual(endOfMonth.dayDateFromAddingDays(1), startOfNextMonth, "Carries over to month unit when needed.")
    }
    func testHourDateFromAddingHours() {
        let endOfToday = calendar.dateBySettingHour(23, minute: 59, second: 59, ofDate: NSDate(), options: [])!
        let tomorrow = calendar.dateByAddingUnit(.Day, value: 1, toDate: midnight, options: [])
        XCTAssertEqual(endOfToday.hourDateFromAddingHours(1), tomorrow, "Carries over to day unit when needed.")
    }

    func testDateWithTime() {
        let endOfToday = calendar.dateBySettingHour(23, minute: 59, second: 59, ofDate: NSDate(), options: [])!
        XCTAssertEqual(endOfToday.dateWithTime(midnight), midnight, "Wraps day unit when needed.")
    }

    func testHasCustomTime() {
        XCTAssertFalse(midnight.hasCustomTime)
        XCTAssertTrue(calendar.dateBySettingHour(1, minute: 1, second: 1, ofDate: NSDate(), options: [])!.hasCustomTime)
        XCTAssertTrue(calendar.dateBySettingHour(1, minute: 1, second: 0, ofDate: NSDate(), options: [])!.hasCustomTime)
        XCTAssertTrue(calendar.dateBySettingHour(1, minute: 0, second: 0, ofDate: NSDate(), options: [])!.hasCustomTime)
    }

}
