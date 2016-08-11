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
        return layout.collectionView!.frame.width - (layout.sectionInset.left + layout.sectionInset.right)
    }
    private var desiredItemHeight: CGFloat {
        return desiredItemSize.height * sizeMultiplier
    }
    private var desiredItemWidth: CGFloat {
        guard availableWidth > desiredItemSize.width else {
            return desiredItemSize.width
        }
        return desiredItemSize.width * sizeMultiplier
    }
    private var isSquare: Bool {
        return desiredItemSize.width == desiredItemSize.height
    }

    // MARK: Level 2 Calculations

    var numberOfColumns: Int {
        return staticNumberOfColumns ?? Int(availableWidth / desiredItemWidth)
    }

    private var columns: CGFloat {
        return CGFloat(numberOfColumns)
    }
    private var dimension: CGFloat {
        let gutters = columns - 1
        let availableCellWidth = availableWidth - (gutters * layout.minimumInteritemSpacing)
        return floor(availableCellWidth / columns)
    }

    // MARK: Level 3 Calculations

    var itemSize: CGSize {
        return CGSize(width: dimension, height: isSquare ? dimension : desiredItemHeight)
    }
    var rowSpaceRemainder: Int {
        return Int(availableWidth - (dimension * columns))
    }

    // MARK: Configuration

    private(set) weak var layout: UICollectionViewFlowLayout!
    private(set) var desiredItemSize: CGSize!
    var sizeMultiplier: CGFloat = 1
    var staticNumberOfColumns: Int?

    init(layout: UICollectionViewFlowLayout, desiredItemSize: CGSize) {
        self.layout = layout
        self.desiredItemSize = desiredItemSize
    }

}
