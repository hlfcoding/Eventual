//
//  CollectionViewFlowLayoutFluidity.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

struct CollectionViewFlowLayoutFluidity {

    weak var layout: UICollectionViewFlowLayout!

    var itemSize: CGSize {
        return CGSize(width: dimension, height: isSquare ? dimension : resizedDesiredItemHeight)
    }
    var numberOfColumns: Int {
        return Int(availableWidth / resizedDesiredItemWidth)
    }
    var rowSpaceRemainder: Int {
        return Int(availableWidth - (dimension * columns))
    }
    var sizeMultiplier: CGFloat = 1

    private var desiredItemSize: CGSize!

    private var availableWidth: CGFloat {
        return layout.collectionView!.frame.width - (layout.sectionInset.left + layout.sectionInset.right)
    }
    private var columns: CGFloat {
        return CGFloat(numberOfColumns)
    }
    private var dimension: CGFloat {
        let gutters = columns - 1
        let availableCellWidth = availableWidth - (gutters * layout.minimumInteritemSpacing)
        return floor(availableCellWidth / columns)
    }
    private var isSquare: Bool {
        return desiredItemSize.width == desiredItemSize.height
    }
    private var resizedDesiredItemHeight: CGFloat {
        return desiredItemSize.height * sizeMultiplier
    }
    private var resizedDesiredItemWidth: CGFloat {
        guard availableWidth > desiredItemSize.width else {
            return desiredItemSize.width
        }
        return desiredItemSize.width * sizeMultiplier
    }

    init(layout: UICollectionViewFlowLayout, desiredItemSize: CGSize) {
        self.layout = layout
        self.desiredItemSize = desiredItemSize
    }

}