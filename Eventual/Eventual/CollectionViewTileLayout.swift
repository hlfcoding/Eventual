//
//  CollectionViewTileLayout.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class CollectionViewTileLayout: UICollectionViewFlowLayout {

    static let deletionViewKind: String = "Deletion"

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

    private var fluidity: CollectionViewFlowLayoutFluidity!
    private var needsBorderUpdate = false
    private var rowSpaceRemainder: Int!
    private var sizeMultiplier: CGFloat {
        switch collectionView!.traitCollection.horizontalSizeClass {
        case .Regular: return regularSizeMultiplier
        case .Compact: return compactSizeMultiplier
        case .Unspecified: return 1
        }
    }

    // NOTE: Drag-to-delete is hacked into the layout by using the layout attribute delegate methods
    // to store and update the state of the drag.
    @IBInspectable var dragToDelete: Bool = false
    @IBInspectable var deletionViewHeight: CGFloat = 0
    var indexPathToDelete: NSIndexPath?
    private var deletionViewLayoutAttributes: CollectionViewTileLayoutAttributes? {
        return layoutAttributesForDecorationViewOfKind(
            CollectionViewTileLayout.deletionViewKind, atIndexPath: NSIndexPath(index: 0))
            as? CollectionViewTileLayoutAttributes
    }
    private var dropToDelete = false

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        minimumLineSpacing = 0
        minimumInteritemSpacing = 0

        let layoutInfo = CollectionViewFlowLayoutFluidity.LayoutInfo(
            desiredItemSize: itemSize,
            minimumInteritemSpacing: CGSize(width: minimumInteritemSpacing, height: minimumLineSpacing),
            sectionInset: sectionInset,
            viewportSize: { [unowned self] in self.collectionView!.bounds.size }
        )
        fluidity = CollectionViewFlowLayoutFluidity(layoutInfo: layoutInfo)
    }

    override func prepareLayout() {
        defer { super.prepareLayout() }

        fluidity.sizeMultiplier = sizeMultiplier

        let previousNumberOfColumns = numberOfColumns
        if dynamicNumberOfColumns {
            numberOfColumns = fluidity.numberOfColumns
        } else {
            fluidity.staticNumberOfColumns = numberOfColumns
        }
        guard numberOfColumns > 0 else { preconditionFailure("Invalid number of columns.") }
        needsBorderUpdate = numberOfColumns != previousNumberOfColumns

        itemSize = fluidity.itemSize
        rowSpaceRemainder = fluidity.rowSpaceRemainder
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard var layoutAttributesCollection = super.layoutAttributesForElementsInRect(rect) as? [CollectionViewTileLayoutAttributes]
            else { return nil }

        for layoutAttributes in layoutAttributesCollection
            where layoutAttributes.representedElementCategory == .Cell {
            configureBordersForLayoutAttributes(layoutAttributes)
        }

        if dragToDelete && indexPathToDelete != nil, let layoutAttributes = deletionViewLayoutAttributes {
            layoutAttributesCollection.append(layoutAttributes)
        }

        return layoutAttributesCollection
    }

    // Some cells need to have a bumped width per rowSpaceRemainder. Otherwise interitem spacing
    // won't be 0 for all cells in the row. Also, the first cell can't get bumped, otherwise
    // UICollectionViewFlowLayout freaks out internally and bumps interitem spacing for remaining
    // cells (for non-full rows). This should be called in the CollectionVC in the layout delegate
    // method of the same name, otherwise itemSize will not be overridden.
    func sizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        let itemIndex = indexPath.item, rowItemIndex = itemIndex % numberOfColumns
        var size = itemSize
        if rowItemIndex > 0 && rowItemIndex <= rowSpaceRemainder {
            size.width += 1
        }
        return size
    }

    private func configureBordersForLayoutAttributes(layoutAttributes: CollectionViewTileLayoutAttributes) {
        let sectionItemCount = collectionView!.numberOfItemsInSection(layoutAttributes.indexPath.section)
        let sectionDescriptor = TileLayoutSectionDescriptor(
            numberOfItems: sectionItemCount - (indexPathToDelete != nil ? 1 : 0),
            numberOfColumns: numberOfColumns
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
        if numberOfColumns == 1 {
            layoutAttributes.borderSizesWithScreenEdges.left = 0
            layoutAttributes.borderSizesWithScreenEdges.right = 0
        }
    }

    override func finalizeAnimatedBoundsChange() {
        super.finalizeAnimatedBoundsChange()
        if needsBorderUpdate {
            collectionView!.reloadData()
        }
    }

    override class func layoutAttributesClass() -> AnyClass {
        return CollectionViewTileLayoutAttributes.self
    }

    // MARK: Interactive Movement

    override func layoutAttributesForInteractivelyMovingItemAtIndexPath(indexPath: NSIndexPath,
                                                                        withTargetPosition position: CGPoint) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = super.layoutAttributesForInteractivelyMovingItemAtIndexPath(indexPath, withTargetPosition: position)
        if dragToDelete, let layoutAttributes = layoutAttributes as? CollectionViewTileLayoutAttributes {
            layoutAttributes.borderSizes = UIEdgeInsetsZero
            layoutAttributes.frame.origin.x = 0
            dropToDelete = layoutAttributes.frame.maxY > deletionViewLayoutAttributes?.frame.minY
        }
        return layoutAttributes
    }

    override func invalidationContextForInteractivelyMovingItems(targetIndexPaths: [NSIndexPath], withTargetPosition targetPosition: CGPoint,
                                                                 previousIndexPaths: [NSIndexPath], previousPosition: CGPoint) -> UICollectionViewLayoutInvalidationContext {
        guard dragToDelete else {
            return super.invalidationContextForInteractivelyMovingItems(
                targetIndexPaths, withTargetPosition: targetPosition, previousIndexPaths: previousIndexPaths, previousPosition: previousPosition)
        }
        return TileInteractiveMovementInvalidationContext()
    }

    override func invalidationContextForEndingInteractiveMovementOfItemsToFinalIndexPaths(indexPaths: [NSIndexPath], previousIndexPaths: [NSIndexPath],
                                                                                          movementCancelled: Bool) -> UICollectionViewLayoutInvalidationContext {
        guard dragToDelete && indexPaths.count == 1 && previousIndexPaths.count == 1 else {
            return super.invalidationContextForEndingInteractiveMovementOfItemsToFinalIndexPaths(
                indexPaths, previousIndexPaths: previousIndexPaths, movementCancelled: movementCancelled)
        }
        if dropToDelete {
            NSNotificationCenter.defaultCenter()
                .postNotification(NSNotification(name: EntityDeletionAction, object: nil))
        }
        indexPathToDelete = nil
        dropToDelete = false
        return TileInteractiveMovementInvalidationContext()
    }

    // FIXME: Does not work as advertised..
    override func initialLayoutAttributesForAppearingDecorationElementOfKind(elementKind: String,
                                                                             atIndexPath decorationIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard dragToDelete else { return nil }
        return generateDeletionViewLayoutAttributesAtIndexPath(decorationIndexPath)
    }

    override func finalLayoutAttributesForDisappearingDecorationElementOfKind(elementKind: String,
                                                                              atIndexPath decorationIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard dragToDelete else { return nil }
        return generateDeletionViewLayoutAttributesAtIndexPath(decorationIndexPath)
    }

    override func layoutAttributesForDecorationViewOfKind(elementKind: String,
                                                          atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard dragToDelete else { return nil }
        let layoutAttributes = generateDeletionViewLayoutAttributesAtIndexPath(indexPath)
        layoutAttributes.frame.origin.y -= layoutAttributes.size.height
        return layoutAttributes
    }

    private func generateDeletionViewLayoutAttributesAtIndexPath(indexPath: NSIndexPath) -> CollectionViewTileLayoutAttributes {
        let layoutAttributes = CollectionViewTileLayoutAttributes(
            forDecorationViewOfKind: CollectionViewTileLayout.deletionViewKind, withIndexPath: indexPath
        )
        layoutAttributes.frame = CGRect(
            x: 0, y: collectionView!.frame.height - collectionView!.contentInset.top,
            width: collectionView!.frame.width, height: deletionViewHeight
        )
        layoutAttributes.zIndex = 1
        return layoutAttributes
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
            copy.borderSize = borderSize
            copy.borderSizes = borderSizes
            copy.borderSizesWithScreenEdges = borderSizesWithScreenEdges
        }
        return copy
    }

    override func isEqual(object: AnyObject?) -> Bool {
        var isEqual = super.isEqual(object)
        if isEqual, let layoutAttributes = object as? CollectionViewTileLayoutAttributes {
            isEqual = UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.borderSizes, borderSizes)
        }
        return isEqual
    }

}

class TileInteractiveMovementInvalidationContext: UICollectionViewFlowLayoutInvalidationContext {
    override var invalidateEverything: Bool { return true }
}
