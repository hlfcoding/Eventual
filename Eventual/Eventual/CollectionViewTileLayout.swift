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
    @IBInspectable var hasDeletionDropZone: Bool = false
    @IBInspectable var deletionDropZoneHeight: CGFloat = 0
    var deletionDropZoneAttributes: UICollectionViewLayoutAttributes? {
        return layoutAttributesForDecorationViewOfKind(CollectionViewTileLayout.deletionViewKind,
                                                       atIndexPath: deletionViewIndexPath)
    }
    var deletionDropZoneHidden = true {
        didSet {
            let context = UICollectionViewFlowLayoutInvalidationContext()
            context.invalidateDecorationElementsOfKind(CollectionViewTileLayout.deletionViewKind,
                                                       atIndexPaths: [deletionViewIndexPath])
            let invalidate: () -> Void = {
                self.collectionView?.performBatchUpdates({
                    self.invalidateLayoutWithContext(context)
                }, completion: nil)
            }

            if deletionDropZoneHidden {
                UIView.animateWithDuration(
                    0.2, delay: 0.5, options: [.CurveEaseIn], animations: invalidate, completion: nil
                )
            } else {
                let (damping, initialVelocity) = Appearance.drawerSpringAnimation
                UIView.animateWithDuration(
                    0.3, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: initialVelocity,
                    options: [], animations: invalidate, completion: nil
                )
            }
        }
    }
    var deletionViewIndexPath = NSIndexPath(index: 0)

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        minimumLineSpacing = 1
        minimumInteritemSpacing = 1

        let layoutInfo = CollectionViewFlowLayoutFluidity.LayoutInfo(
            desiredItemSize: itemSize,
            minimumInteritemSpacing: CGSize(width: minimumInteritemSpacing, height: minimumLineSpacing),
            sectionInset: sectionInset,
            viewportSize: viewportSize
        )
        fluidity = CollectionViewFlowLayoutFluidity(layoutInfo: layoutInfo)
    }

    func viewportSize() -> CGSize {
        return collectionView!.bounds.size
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
        guard var layoutAttributesCollection = super.layoutAttributesForElementsInRect(rect) else { return nil }

        if hasDeletionDropZone {
            guard let layoutAttributes = layoutAttributesForDecorationViewOfKind(
                CollectionViewTileLayout.deletionViewKind, atIndexPath: deletionViewIndexPath)
                else { preconditionFailure() }
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

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }

    // MARK: Deletion Drop-zone

    override func initialLayoutAttributesForAppearingDecorationElementOfKind(elementKind: String,
                                                                             atIndexPath decorationIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard hasDeletionDropZone else { return nil }
        return generateDeletionViewLayoutAttributesAtIndexPath(decorationIndexPath)
    }

    override func finalLayoutAttributesForDisappearingDecorationElementOfKind(elementKind: String,
                                                                              atIndexPath decorationIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard hasDeletionDropZone else { return nil }
        return generateDeletionViewLayoutAttributesAtIndexPath(decorationIndexPath)
    }

    override func layoutAttributesForDecorationViewOfKind(elementKind: String,
                                                          atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard hasDeletionDropZone else { return nil }
        let layoutAttributes = generateDeletionViewLayoutAttributesAtIndexPath(indexPath)
        if !deletionDropZoneHidden {
            layoutAttributes.frame.origin.y -= layoutAttributes.size.height
        }
        return layoutAttributes
    }

    private func generateDeletionViewLayoutAttributesAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = UICollectionViewLayoutAttributes(
            forDecorationViewOfKind: CollectionViewTileLayout.deletionViewKind, withIndexPath: indexPath
        )
        layoutAttributes.frame = CGRect(
            x: 0, y: collectionView!.frame.height + collectionView!.contentOffset.y,
            width: collectionView!.frame.width, height: deletionDropZoneHeight
        )
        layoutAttributes.zIndex = 9999
        return layoutAttributes
    }

}
