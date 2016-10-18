//
//  CollectionViewTileLayout.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class CollectionViewTileLayout: UICollectionViewFlowLayout {

    var viewportYOffset: CGFloat {
        let application = UIApplication.shared
        guard
            let navigationController = application.keyWindow?.rootViewController as? UINavigationController
            else { return CGFloat(0) }

        var offset = navigationController.navigationBar.frame.height
        if !application.isStatusBarHidden {
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
        case .regular: return regularSizeMultiplier
        case .compact: return compactSizeMultiplier
        case .unspecified: return 1
        }
    }

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

    func completeSetUp() {
        if hasDeletionDropzone {
            register(UINib(nibName: String(describing: DeletionDropzoneView.self), bundle: Bundle.main),
                     forDecorationViewOfKind: DeletionDropzoneAttributes.kind)
        }
    }

    override func prepare() {
        defer { super.prepare() }

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

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard var attributesCollection = super.layoutAttributesForElements(in: rect) else { return nil }

        for (index, attributes) in attributesCollection.enumerated() where attributes.representedElementCategory == .cell {
            // Some cells need to have a bumped width per rowSpaceRemainder. Otherwise interitem spacing
            // won't be 0 for all cells in the row. Also, the first cell can't get bumped, otherwise
            // UICollectionViewFlowLayout freaks out internally and bumps interitem spacing for remaining
            // cells (for non-full rows).
            let rowItemIndex = attributes.indexPath.item % numberOfColumns
            if rowItemIndex > 0 && rowItemIndex <= rowSpaceRemainder,
                let newAttributes = attributes.copy() as? UICollectionViewLayoutAttributes {
                let offset: CGFloat = 1
                newAttributes.frame.origin.x -= offset
                newAttributes.frame.size.width += offset
                attributesCollection[index] = newAttributes
            }
        }

        if hasDeletionDropzone {
            guard let attributes = deletionDropzoneAttributes else { preconditionFailure() }
            attributesCollection.append(attributes)
        }

        return attributesCollection
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    // MARK: - Deletion Drop-zone

    // NOTE: Drag-to-delete is hacked into the layout by using the layout attribute delegate methods
    // to store and update the state of the drag.
    @IBInspectable var hasDeletionDropzone: Bool = false
    @IBInspectable var deletionDropzoneHeight: CGFloat = 0
    var deletionDropzoneAttributes: DeletionDropzoneAttributes? {
        let attributes = layoutAttributesForDecorationView(
            ofKind: DeletionDropzoneAttributes.kind, at: deletionViewIndexPath
        )
        return attributes as? DeletionDropzoneAttributes
    }
    var isDeletionDropzoneHidden = true {
        didSet {
            if isDeletionDropzoneHidden {
                UIView.animate(
                    withDuration: 0.2, delay: 0.5, options: .curveEaseIn,
                    animations: invalidateDeletionDropzone, completion: nil
                )
            } else {
                let (damping, initialVelocity) = Appearance.drawerSpringAnimation
                UIView.animate(
                    withDuration: 0.3, delay: 0,
                    usingSpringWithDamping: damping, initialSpringVelocity: initialVelocity,
                    options: [], animations: invalidateDeletionDropzone, completion: nil
                )
            }
        }
    }
    var isDeletionTextHidden = true {
        didSet {
            guard !isDeletionDropzoneHidden else { return }
            invalidateDeletionDropzone()
        }
    }
    var deletionViewIndexPath = IndexPath(index: 0)

    override func layoutAttributesForDecorationView(ofKind elementKind: String,
                                                    at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard hasDeletionDropzone else { return nil }
        return generateDeletionViewLayoutAttributes(at: indexPath)
    }

    private func generateDeletionViewLayoutAttributes(at indexPath: IndexPath) -> DeletionDropzoneAttributes {
        let attributes = DeletionDropzoneAttributes(
            forDecorationViewOfKind: DeletionDropzoneAttributes.kind, with: indexPath
        )
        attributes.frame = CGRect(
            x: 0, y: collectionView!.frame.height + collectionView!.contentOffset.y,
            width: collectionView!.frame.width, height: deletionDropzoneHeight
        )
        if !isDeletionDropzoneHidden {
            attributes.frame.origin.y -= attributes.size.height
        } else {
            isDeletionTextHidden = true
        }
        attributes.isTextVisible = !isDeletionTextHidden
        attributes.zIndex = 9999
        return attributes
    }

    private func invalidateDeletionDropzone() {
        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.invalidateDecorationElements(ofKind: DeletionDropzoneAttributes.kind,
                                             at: [deletionViewIndexPath])
        collectionView?.performBatchUpdates({
            self.invalidateLayout(with: context)
        }, completion: nil)
    }

    func canDeleteCellOnDrop(cellFrame: CGRect) -> Bool {
        guard let attributes = deletionDropzoneAttributes else { return false }
        let canDelete = attributes.frame.intersects(cellFrame)
        isDeletionTextHidden = !canDelete
        return canDelete
    }

    func finalFrameForDroppedCell() -> CGRect {
        guard let attributes = deletionDropzoneAttributes else { preconditionFailure() }
        return CGRect(origin: attributes.center, size: .zero)
    }

    func maxYForDraggingCell() -> CGFloat {
        guard let collectionView = collectionView else { preconditionFailure() }
        return (collectionView.bounds.height + collectionView.contentOffset.y
            - deletionDropzoneHeight + CollectionViewTileCell.borderSize)
    }

    func minYForDraggingCell() -> CGFloat {
        guard let collectionView = collectionView else { preconditionFailure() }
        return collectionView.bounds.minY + viewportYOffset
    }

}

final class DeletionDropzoneAttributes: UICollectionViewLayoutAttributes {

    static let kind = "Deletion"

    var isTextVisible = false

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! DeletionDropzoneAttributes
        copy.isTextVisible = isTextVisible
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? DeletionDropzoneAttributes else { return false }
        guard super.isEqual(object) else { return false }
        return object.isTextVisible == isTextVisible
    }

}
