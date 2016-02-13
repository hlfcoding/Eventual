//
//  CollectionViewTileLayoutTests.swift
//  Eventual
//
//  Created by Peng Wang on 1/1/16.
//  Copyright (c) 2016 Eventual App. All rights reserved.
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
        /**
          _ _
         |_|_|
         |_|

        */
        var section = TileLayoutSectionDescriptor(numberOfItems: 3, numberOfColumns: 2)

        var item = TileLayoutItemDescriptor(index: 0, section: section)
        XCTAssertEqual(item.indexInRow, 0)
        XCTAssertEqual(item.numberOfNextRowItems, 1)
        XCTAssertFalse(item.isBottomEdgeItem)
        XCTAssertFalse(item.isOnPartlyFilledLastRow)
        XCTAssertFalse(item.isSoloRowItem)
        XCTAssertTrue(item.isTopEdgeItem)

        item.index = 2
        XCTAssertEqual(item.indexInRow, 0)
        XCTAssertEqual(item.numberOfNextRowItems, 1)
        XCTAssertTrue(item.isBottomEdgeItem)
        XCTAssertTrue(item.isOnPartlyFilledLastRow)
        XCTAssertFalse(item.isSoloRowItem)
        XCTAssertFalse(item.isTopEdgeItem)

        /**
          _ _
         |_|_|
         |_|_|
         |_|

        */
        section = TileLayoutSectionDescriptor(numberOfItems: 5, numberOfColumns: 2)
        item = TileLayoutItemDescriptor(index: 2, section: section)
        XCTAssertEqual(item.indexInRow, 0)
        XCTAssertEqual(item.numberOfNextRowItems, 1)
        XCTAssertFalse(item.isBottomEdgeItem)
        XCTAssertFalse(item.isOnPartlyFilledLastRow)
        XCTAssertFalse(item.isSoloRowItem)
        XCTAssertFalse(item.isTopEdgeItem)

        item.index = 3
        XCTAssertEqual(item.indexInRow, 1)
        XCTAssertEqual(item.numberOfNextRowItems, 0)
        XCTAssertTrue(item.isBottomEdgeItem)
        XCTAssertFalse(item.isOnPartlyFilledLastRow)
        XCTAssertFalse(item.isSoloRowItem)
        XCTAssertFalse(item.isTopEdgeItem)

        /**
          _ _
         |_|_|

        */
        section = TileLayoutSectionDescriptor(numberOfItems: 2, numberOfColumns: 2)
        item = TileLayoutItemDescriptor(index: 0, section: section)
        XCTAssertEqual(item.indexInRow, 0)
        XCTAssertEqual(item.numberOfNextRowItems, 1)
        XCTAssertTrue(item.isBottomEdgeItem)
        XCTAssertFalse(item.isOnPartlyFilledLastRow)
        XCTAssertTrue(item.isSoloRowItem)
        XCTAssertTrue(item.isTopEdgeItem)
    }

    func testItemDescriptor() {
        /**
          _ _
         |_|_|
         |_|

        */
        var section = TileLayoutSectionDescriptor(numberOfItems: 3, numberOfColumns: 2)

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

        /**
          _ _
         |_|_|
         |_|_|
         |_|

        */
        section = TileLayoutSectionDescriptor(numberOfItems: 5, numberOfColumns: 2)
        item = TileLayoutItemDescriptor(index: 0, section: section)
        XCTAssertFalse(item.isBottomBorderVisible)
        XCTAssertTrue(item.isRightBorderVisible)
        XCTAssertTrue(item.isTopBorderVisible)

        item.index = 1
        XCTAssertFalse(item.isBottomBorderVisible)
        XCTAssertFalse(item.isRightBorderVisible)
        XCTAssertTrue(item.isTopBorderVisible)

        item.index = 2
        XCTAssertTrue(item.isBottomBorderVisible)
        XCTAssertTrue(item.isRightBorderVisible)
        XCTAssertTrue(item.isTopBorderVisible)

        item.index = 3
        XCTAssertTrue(item.isBottomBorderVisible)
        XCTAssertFalse(item.isRightBorderVisible)
        XCTAssertTrue(item.isTopBorderVisible)

        item.index = 4
        XCTAssertTrue(item.isBottomBorderVisible)
        XCTAssertTrue(item.isRightBorderVisible)
        XCTAssertFalse(item.isTopBorderVisible)


        /**
          _ _
         |_|_|

        */
        section = TileLayoutSectionDescriptor(numberOfItems: 2, numberOfColumns: 2)
        item = TileLayoutItemDescriptor(index: 0, section: section)
        XCTAssertTrue(item.isBottomBorderVisible)
        XCTAssertTrue(item.isRightBorderVisible)
        XCTAssertTrue(item.isTopBorderVisible)

        item.index = 1
        XCTAssertTrue(item.isBottomBorderVisible)
        XCTAssertFalse(item.isRightBorderVisible)
        XCTAssertTrue(item.isTopBorderVisible)
    }

}
