//
//  CollectionViewTileLayoutTests.swift
//  Eventual
//
//  Created by Peng Wang on 1/1/16.
//  Copyright © 2016 Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

class CollectionViewTileLayoutTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSectionDescriptor() {
        var section = TileLayoutSectionDescriptor(numberOfItems: 0, numberOfColumns: 2)
        XCTAssertEqual(section.indexOfLastRowItem, 1)

        section.numberOfItems = 1
        XCTAssertEqual(section.indexOfLastItem, 0)
        XCTAssertEqual(section.indexOfItemBeforeBottomEdge, 0)

        section.numberOfItems = 4
        XCTAssertEqual(section.indexOfLastItem, 3)
        XCTAssertEqual(section.indexOfItemBeforeBottomEdge, 1)
    }

    func testItemDescriptorInternals() {
        let section = TileLayoutSectionDescriptor(numberOfItems: 3, numberOfColumns: 2)

        var item = TileLayoutItemDescriptor(index: 0, section: section)
        XCTAssertEqual(item.indexInRow, 0)
        XCTAssertEqual(item.numberOfNextRowItems, 1)
        XCTAssertFalse(item.isBottomEdgeCell)
        XCTAssertFalse(item.isOnPartialLastRow)
        XCTAssertFalse(item.isSingleRowCell)
        XCTAssertTrue(item.isTopEdgeCell)

        item.index = 2
        XCTAssertEqual(item.indexInRow, 0)
        XCTAssertEqual(item.numberOfNextRowItems, 1)
        XCTAssertTrue(item.isBottomEdgeCell)
        XCTAssertTrue(item.isOnPartialLastRow)
        XCTAssertFalse(item.isSingleRowCell)
        XCTAssertFalse(item.isTopEdgeCell)
    }

    func testItemDescriptor() {
        let section = TileLayoutSectionDescriptor(numberOfItems: 3, numberOfColumns: 2)

        var item = TileLayoutItemDescriptor(index: 0, section: section)
        XCTAssertTrue(item.isBottomBorderVisible)
        XCTAssertTrue(item.isRightBorderVisible)
        XCTAssertTrue(item.isTopBorderVisible)

        item.index = 1
        XCTAssertTrue(item.isBottomBorderVisible)
        XCTAssertFalse(item.isRightBorderVisible)
        XCTAssertTrue(item.isTopBorderVisible)

        item.index = 2
        XCTAssertTrue(item.isBottomBorderVisible)
        XCTAssertTrue(item.isRightBorderVisible)
        XCTAssertFalse(item.isTopBorderVisible)
    }

}
