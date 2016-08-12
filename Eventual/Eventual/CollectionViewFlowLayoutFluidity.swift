//
//  CollectionViewFlowLayoutFluidity.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

/**
 Equal-width item sizing and stretching to fill the available width, with the remainder going to
 `rowSpaceRemainder`. Values are always computed. A `sizeMultiplier` can be configured. You can use
 `staticNumberOfColumns` to only opt out of dynamic columns. Inspired by [CSS fluid layouts][].
 
 [CSS fluid layouts]: https://smashingmagazine.com/2009/06/fixed-vs-fluid-vs-elastic-layout-whats-the-right-one-for-you/#fluid-website-layouts
 */
struct CollectionViewFlowLayoutFluidity {

    // MARK: Level 1 Calculations

    private var availableWidth: CGFloat {
        return layoutInfo.viewportSize().width - (layoutInfo.sectionInset.left + layoutInfo.sectionInset.right)
    }
    private var desiredItemHeight: CGFloat {
        return layoutInfo.desiredItemSize.height * sizeMultiplier
    }
    private var desiredItemWidth: CGFloat {
        guard availableWidth > layoutInfo.desiredItemSize.width else {
            return layoutInfo.desiredItemSize.width
        }
        return layoutInfo.desiredItemSize.width * sizeMultiplier
    }
    private var isSquare: Bool {
        return layoutInfo.desiredItemSize.width == layoutInfo.desiredItemSize.height
    }

    // MARK: Level 2 Calculations

    var numberOfColumns: Int {
        return staticNumberOfColumns ?? Int(availableWidth / desiredItemWidth)
    }

    private var columns: CGFloat {
        return CGFloat(numberOfColumns)
    }
    private var dimension: CGFloat {
        let availableCellWidth = availableWidth - guttersWidth
        return floor(availableCellWidth / columns)
    }
    private var guttersWidth: CGFloat {
        let gutters = columns - 1
        return gutters * layoutInfo.minimumInteritemSpacing.width
    }

    // MARK: Level 3 Calculations

    var itemSize: CGSize {
        return CGSize(width: dimension, height: isSquare ? dimension : desiredItemHeight)
    }
    var rowSpaceRemainder: Int {
        let cellsWidth = dimension * columns
        return Int(availableWidth - (guttersWidth + cellsWidth))
    }

    // MARK: Configuration

    struct LayoutInfo {
        var desiredItemSize: CGSize
        var minimumInteritemSpacing: CGSize
        var sectionInset: UIEdgeInsets
        var viewportSize: () -> CGSize
    }
    private(set) var layoutInfo: LayoutInfo!
    var sizeMultiplier: CGFloat = 1
    var staticNumberOfColumns: Int?

    init(layoutInfo: LayoutInfo) {
        self.layoutInfo = layoutInfo
    }

}

