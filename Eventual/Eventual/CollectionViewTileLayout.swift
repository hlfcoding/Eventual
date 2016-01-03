//
//  CollectionViewTileLayout.swift
//  Eventual
//
//  Created by Peng Wang on 10/11/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

class CollectionViewTileLayout: UICollectionViewFlowLayout {

    var viewportYOffset: CGFloat {
        let application = UIApplication.sharedApplication()
        guard let navigationController = application.keyWindow?.rootViewController as? UINavigationController
              else { return CGFloat(0) }
        var offset = navigationController.navigationBar.frame.size.height
        if !application.statusBarHidden {
            offset += application.statusBarFrame.size.height
        }
        return offset
    }

    // NOTE: This can be false if cells are not uniform in height.
    @IBInspectable var dynamicNumberOfColumns: Bool = true
    @IBInspectable var numberOfColumns: Int = 1

    private var desiredItemSize: CGSize!
    private var needsBorderUpdate = false
    private var rowSpaceRemainder = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.desiredItemSize = self.itemSize

        self.minimumLineSpacing = 0.0
        self.minimumInteritemSpacing = 0.0
    }

    override func prepareLayout() {
        defer { super.prepareLayout() }

        let previousNumberOfColumns = self.numberOfColumns

        let availableWidth = self.collectionView!.frame.size.width - (self.sectionInset.left + self.sectionInset.right)
        if self.dynamicNumberOfColumns {
            self.numberOfColumns = Int(availableWidth / self.desiredItemSize.width)
        }
        guard self.numberOfColumns > 0 else { assertionFailure("Invalid number of columns."); return }

        self.needsBorderUpdate = self.numberOfColumns != previousNumberOfColumns

        let numberOfColumns = CGFloat(self.numberOfColumns)
        let numberOfGutters = numberOfColumns - 1
        let availableCellWidth = availableWidth - (numberOfGutters * self.minimumInteritemSpacing)
        let dimension = floor(availableCellWidth / numberOfColumns)
        let isSquare = self.desiredItemSize.width == self.desiredItemSize.height
        self.rowSpaceRemainder = Int(availableWidth - (dimension * numberOfColumns))
        self.itemSize = CGSize(width: dimension, height: isSquare ? dimension : desiredItemSize.height)
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributesCollection = super.layoutAttributesForElementsInRect(rect)
        if let layoutAttributesCollection = layoutAttributesCollection as? [CollectionViewTileLayoutAttributes] {
            for layoutAttributes in layoutAttributesCollection
                where layoutAttributes.representedElementCategory == .Cell
            {
                self.configureBordersForLayoutAttributes(layoutAttributes)
            }
        }
        return layoutAttributesCollection
    }

    // Some cells need to have a bumped width per rowSpaceRemainder. Otherwise interitem spacing
    // won't be 0 for all cells in the row. Also, the first cell can't get bumped, otherwise
    // UICollectionViewFlowLayout freaks out internally and bumps interitem spacing for remaining
    // cells (for non-full rows). This should be called in the CollectionVC in the layout delegate
    // method of the same name, otherwise itemSize will not be overridden.
    func sizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        let itemIndex = indexPath.item
        let rowItemIndex = itemIndex % self.numberOfColumns
        var size = self.itemSize
        guard rowItemIndex > 0 && rowItemIndex <= self.rowSpaceRemainder else { return size }
        size.width += 1
        return size
    }

    private func configureBordersForLayoutAttributes(layoutAttributes: CollectionViewTileLayoutAttributes)
    {
        let sectionDescriptor = TileLayoutSectionDescriptor(
            numberOfItems: self.collectionView!.numberOfItemsInSection(layoutAttributes.indexPath.section),
            numberOfColumns: self.numberOfColumns
        )
        let itemDescriptor = TileLayoutItemDescriptor(
            index: layoutAttributes.indexPath.item,
            section: sectionDescriptor
        )

        if !itemDescriptor.isRightBorderVisible {
            layoutAttributes.borderSizes.right = 0.0
        }
        if !itemDescriptor.isTopBorderVisible {
            layoutAttributes.borderSizes.top = 0.0
            layoutAttributes.borderSizesWithScreenEdges.top = 0.0
        }
        if itemDescriptor.isBottomBorderVisible {
            layoutAttributes.borderSizes.bottom = layoutAttributes.borderSize
            layoutAttributes.borderSizesWithScreenEdges.bottom = layoutAttributes.borderSize
        }

        if itemDescriptor.indexInRow == 0 {
            layoutAttributes.borderSizesWithScreenEdges.left = layoutAttributes.borderSize
        }
        if itemDescriptor.indexInRow == itemDescriptor.section.indexOfLastRowItem {
            layoutAttributes.borderSizesWithScreenEdges.right = layoutAttributes.borderSize
        }
    }

    override func finalizeAnimatedBoundsChange() {
        super.finalizeAnimatedBoundsChange()
        if self.needsBorderUpdate {
            self.collectionView!.reloadData()
        }
    }

    override class func layoutAttributesClass() -> AnyClass {
        return CollectionViewTileLayoutAttributes.self
    }

}

struct TileLayoutItemDescriptor {

    var index: Int!
    var section: TileLayoutSectionDescriptor!

    init(index: Int, section: TileLayoutSectionDescriptor) {
        self.index = index
        self.section = section
    }

    // NOTE: Omitting `self` here.

    var indexInRow: Int { return index % section.numberOfColumns }
    var numberOfNextRowItems: Int { return section.indexOfLastRowItem - indexInRow }

    var isBottomEdgeItem: Bool { return index > section.indexOfItemBeforeBottomEdge || isSoloRowItem }
    var isOnPartlyFilledLastRow: Bool { return index + numberOfNextRowItems > section.indexOfLastItem }
    var isOnRowWithBottomEdgeItem: Bool {
        return !isBottomEdgeItem && (index + numberOfNextRowItems > section.indexOfItemBeforeBottomEdge)
    }
    var isSoloRowItem: Bool { return section.numberOfItems <= section.numberOfColumns }
    var isTopEdgeItem: Bool { return index < section.numberOfColumns }

    // NOTE: Where the border gets drawn is important. If one of the row-items is a bottom-edge
    // item, which has a bottom border, the other row-items must have the bottom border as well,
    // leaving any items on the next row without top borders. This is to prevent misaligned borders.
    var isBottomBorderVisible: Bool {
        return isBottomEdgeItem || isOnRowWithBottomEdgeItem || (isTopEdgeItem && isSoloRowItem)
    }
    var isRightBorderVisible: Bool { return indexInRow != section.indexOfLastRowItem }
    var isTopBorderVisible: Bool {
        return !isOnPartlyFilledLastRow || isOnRowWithBottomEdgeItem || isSoloRowItem
    }

}

struct TileLayoutSectionDescriptor {

    var numberOfItems: Int!
    var numberOfColumns: Int!

    init(numberOfItems: Int, numberOfColumns: Int) {
        self.numberOfItems = numberOfItems
        self.numberOfColumns = numberOfColumns
    }

    // NOTE: Omitting `self` here.

    var indexOfLastItem: Int { return max(numberOfItems - 1, 0) }
    var indexOfLastRowItem: Int { return numberOfColumns - 1 }
    var indexOfItemBeforeBottomEdge: Int { return max(indexOfLastItem - numberOfColumns, 0) }

}

class CollectionViewTileLayoutAttributes: UICollectionViewLayoutAttributes {

    static let defaultBorderSize: CGFloat = 1.0
    static let defaultBorderSizes = UIEdgeInsets(top: 1.0, left: 0.0, bottom: 0.0, right: 1.0)

    var borderSize = CollectionViewTileLayoutAttributes.defaultBorderSize

    var borderSizes = CollectionViewTileLayoutAttributes.defaultBorderSizes
    var borderSizesWithScreenEdges = CollectionViewTileLayoutAttributes.defaultBorderSizes

    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy: AnyObject = super.copyWithZone(zone)
        if let copy = copy as? CollectionViewTileLayoutAttributes {
            copy.borderSize = self.borderSize
            copy.borderSizes = self.borderSizes
            copy.borderSizesWithScreenEdges = self.borderSizesWithScreenEdges
        }
        return copy
    }

    override func isEqual(object: AnyObject?) -> Bool {
        var isEqual = super.isEqual(object)
        if isEqual, let layoutAttributes = object as? CollectionViewTileLayoutAttributes {
            isEqual = UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.borderSizes, self.borderSizes)
        }
        return isEqual
    }

}
