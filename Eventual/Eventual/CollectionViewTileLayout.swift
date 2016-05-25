//
//  CollectionViewTileLayout.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class CollectionViewTileLayout: UICollectionViewFlowLayout {

    var viewportYOffset: CGFloat {
        let application = UIApplication.sharedApplication()
        guard
            let navigationController = application.keyWindow?.rootViewController as? UINavigationController
            else { return CGFloat(0) }

        var offset = navigationController.navigationBar.frame.height
        if !application.statusBarHidden {
            offset += application.statusBarFrame.height
        }
        return offset
    }

    // NOTE: This can be false if cells are not uniform in height.
    @IBInspectable var dynamicNumberOfColumns: Bool = true
    @IBInspectable var numberOfColumns: Int = 1

    // NOTE: Cannot be added in IB as of Xcode 7.
    @IBInspectable var compactSizeMultiplier: CGFloat = 1
    @IBInspectable var regularSizeMultiplier: CGFloat = 1.2
    private var sizeMultiplier: CGFloat {
        switch self.collectionView!.traitCollection.horizontalSizeClass {
        case .Regular: return self.regularSizeMultiplier
        case .Compact: return self.compactSizeMultiplier
        case .Unspecified: return 1
        }
    }

    private var desiredItemSize: CGSize!
    private var interactivelyMovingIndexPaths = []
    private var needsBorderUpdate = false
    private var rowSpaceRemainder = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.desiredItemSize = self.itemSize

        self.minimumLineSpacing = 0
        self.minimumInteritemSpacing = 0
    }

    override func prepareLayout() {
        defer { super.prepareLayout() }

        let previousNumberOfColumns = self.numberOfColumns
        let availableWidth = self.collectionView!.frame.width - (self.sectionInset.left + self.sectionInset.right)

        if self.dynamicNumberOfColumns {
            let resizedDesiredItemWidth = {
                guard availableWidth > self.desiredItemSize.width else {
                    return self.desiredItemSize.width
                }
                return self.desiredItemSize.width * self.sizeMultiplier
                }() as CGFloat
            self.numberOfColumns = Int(availableWidth / resizedDesiredItemWidth)
        }
        guard self.numberOfColumns > 0 else {
            assertionFailure("Invalid number of columns.")
            return
        }

        self.needsBorderUpdate = self.numberOfColumns != previousNumberOfColumns

        let numberOfColumns = CGFloat(self.numberOfColumns)
        let dimension: CGFloat = {
            let numberOfGutters = numberOfColumns - 1
            let availableCellWidth = availableWidth - (numberOfGutters * self.minimumInteritemSpacing)
            return floor(availableCellWidth / numberOfColumns)
            }()
        self.rowSpaceRemainder = Int(availableWidth - (dimension * numberOfColumns))
        self.itemSize = {
            let isSquare = self.desiredItemSize.width == self.desiredItemSize.height
            let resizedDesiredItemHeight = self.desiredItemSize.height * self.sizeMultiplier
            return CGSize(width: dimension, height: isSquare ? dimension : resizedDesiredItemHeight)
            }()
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
        let itemIndex = indexPath.item, rowItemIndex = itemIndex % self.numberOfColumns
        var size = self.itemSize
        if rowItemIndex > 0 && rowItemIndex <= self.rowSpaceRemainder {
            size.width += 1
        }
        return size
    }

    private func configureBordersForLayoutAttributes(layoutAttributes: CollectionViewTileLayoutAttributes)
    {
        let interactivelyMovingSectionItemCount = self.interactivelyMovingIndexPaths
            .filter({ $0.section == layoutAttributes.indexPath.section })
            .count
        let sectionItemCount = self.collectionView!.numberOfItemsInSection(layoutAttributes.indexPath.section)
        let sectionDescriptor = TileLayoutSectionDescriptor(
            numberOfItems: sectionItemCount - interactivelyMovingSectionItemCount,
            numberOfColumns: self.numberOfColumns
        )
        let itemDescriptor = TileLayoutItemDescriptor(
            index: layoutAttributes.indexPath.item,
            section: sectionDescriptor
        )

        if !itemDescriptor.isRightBorderVisible {
            layoutAttributes.borderSizes.right = 0
        }
        if !itemDescriptor.isTopBorderVisible {
            layoutAttributes.borderSizes.top = 0
            layoutAttributes.borderSizesWithScreenEdges.top = 0
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
        if self.numberOfColumns == 1 {
            layoutAttributes.borderSizesWithScreenEdges.left = 0
            layoutAttributes.borderSizesWithScreenEdges.right = 0
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

    // MARK: Interactive Movement

    override func layoutAttributesForInteractivelyMovingItemAtIndexPath(
        indexPath: NSIndexPath, withTargetPosition position: CGPoint)
        -> UICollectionViewLayoutAttributes
    {
        let layoutAttributes = super.layoutAttributesForInteractivelyMovingItemAtIndexPath(indexPath, withTargetPosition: position)
        if let layoutAttributes = layoutAttributes as? CollectionViewTileLayoutAttributes {
            layoutAttributes.borderSizes = UIEdgeInsetsZero
        }
        return layoutAttributes
    }

    override func invalidationContextForInteractivelyMovingItems(
        targetIndexPaths: [NSIndexPath], withTargetPosition targetPosition: CGPoint,
        previousIndexPaths: [NSIndexPath], previousPosition: CGPoint)
        -> UICollectionViewLayoutInvalidationContext
    {
        self.interactivelyMovingIndexPaths = targetIndexPaths
        return TileInteractiveMovementInvalidationContext()
    }

    override func invalidationContextForEndingInteractiveMovementOfItemsToFinalIndexPaths(
        indexPaths: [NSIndexPath], previousIndexPaths: [NSIndexPath], movementCancelled: Bool)
        -> UICollectionViewLayoutInvalidationContext
    {
        self.interactivelyMovingIndexPaths = []
        return TileInteractiveMovementInvalidationContext()
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

    static let defaultBorderSize: CGFloat = 1
    static let defaultBorderSizes = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 1)

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

class TileInteractiveMovementInvalidationContext: UICollectionViewFlowLayoutInvalidationContext {
    override var invalidateEverything: Bool { return true }
}
