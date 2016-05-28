//
//  DayMenuDataSourceTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class DayMenuDataSourceTests: XCTestCase {

    lazy var dataSource = DayMenuDataSource()

    func testDateFromDayIdentifier() {
        XCTAssertEqual(self.dataSource.dateFromDayIdentifier(self.dataSource.todayIdentifier), NSDate().dayDate)
        XCTAssertEqual(self.dataSource.dateFromDayIdentifier(self.dataSource.tomorrowIdentifier), NSDate().dayDateFromAddingDays(1))
        XCTAssertEqual(self.dataSource.dateFromDayIdentifier(self.dataSource.laterIdentifier), NSDate().dayDateFromAddingDays(2))
    }

    func testIdentifierFromItem() {
        let todayItem = UILabel(frame: CGRectZero)
        todayItem.text = self.dataSource.todayIdentifier
        XCTAssertEqual(self.dataSource.identifierFromItem(todayItem), self.dataSource.todayIdentifier)

        let tomorrowItem = UILabel(frame: CGRectZero)
        tomorrowItem.text = self.dataSource.tomorrowIdentifier
        XCTAssertEqual(self.dataSource.identifierFromItem(tomorrowItem), self.dataSource.tomorrowIdentifier)

        let laterItem = UIButton(frame: CGRectZero)
        laterItem.setTitle(self.dataSource.laterIdentifier, forState: .Normal)
        XCTAssertEqual(self.dataSource.identifierFromItem(laterItem), self.dataSource.laterIdentifier)

        XCTAssertNil(self.dataSource.identifierFromItem(UIView(frame: CGRectZero)))
    }

    func testIndexFromDate() {
        XCTAssertEqual(self.dataSource.indexFromDate(NSDate().dayDate), 0)
        XCTAssertEqual(self.dataSource.indexFromDate(NSDate().dayDateFromAddingDays(1)), 1)
        XCTAssertEqual(self.dataSource.indexFromDate(NSDate().dayDateFromAddingDays(2)), 2)
    }

    func testItemAtIndex() {
        let (type0, identifier0) = self.dataSource.itemAtIndex(0)
        XCTAssertEqual(type0, NavigationTitleItemType.Label)
        XCTAssertEqual(identifier0, self.dataSource.todayIdentifier)

        let (type1, identifier1) = self.dataSource.itemAtIndex(1)
        XCTAssertEqual(type1, NavigationTitleItemType.Label)
        XCTAssertEqual(identifier1, self.dataSource.tomorrowIdentifier)

        let (type2, identifier2) = self.dataSource.itemAtIndex(2)
        XCTAssertEqual(type2, NavigationTitleItemType.Button)
        XCTAssertEqual(identifier2, self.dataSource.laterIdentifier)
    }

}
