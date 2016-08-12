//
//  CollectionViewFlowLayoutFluidityTests.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class CollectionViewFlowLayoutFluidityTests: XCTestCase {

    let defaultLayoutInfo = CollectionViewFlowLayoutFluidity.LayoutInfo(
        desiredItemSize: CGSize(width: 150, height: 150),
        minimumInteritemSpacing: CGSize(width: 10, height: 10),
        sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
        viewportSize: { CGSize(width: 320, height: 480) }
    )

    func testDefaultMetrics() {
        let fluidity = CollectionViewFlowLayoutFluidity(layoutInfo: defaultLayoutInfo)
        XCTAssertEqual(fluidity.numberOfColumns, 2)
        XCTAssertEqual(fluidity.itemSize, CGSize(width: 145, height: 145))
        XCTAssertEqual(fluidity.rowSpaceRemainder, 0)
    }

    func testMetricsWithSizeMultiplier() {
        var fluidity = CollectionViewFlowLayoutFluidity(layoutInfo: defaultLayoutInfo)
        fluidity.sizeMultiplier = 0.6
        XCTAssertEqual(fluidity.numberOfColumns, 3)
        XCTAssertEqual(fluidity.itemSize, CGSize(width: 93, height: 93))
        XCTAssertEqual(fluidity.rowSpaceRemainder, 1)
    }

    func testMetricsWithStaticNumberOfColumns() {
        var fluidity = CollectionViewFlowLayoutFluidity(layoutInfo: defaultLayoutInfo)
        fluidity.staticNumberOfColumns = 1
        XCTAssertEqual(fluidity.numberOfColumns, 1)
        XCTAssertEqual(fluidity.itemSize, CGSize(width: 300, height: 300))
        XCTAssertEqual(fluidity.rowSpaceRemainder, 0)
    }

}
