//
//  CollectionViewTileLayout.swift
//  Eventual
//
//  Created by Peng Wang on 10/11/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

@objc(ETCollectionViewTileLayout) class CollectionViewTileLayout: UICollectionViewFlowLayout, ZoomTransitionControllerDelegate {
    
    var viewportYOffset: CGFloat = 0.0
    func updateViewportYOffset() {
        let application = UIApplication.sharedApplication()
        if let navigationController = application.keyWindow!.rootViewController as? UINavigationController {
            self.viewportYOffset = navigationController.navigationBar.frame.size.height
            if !application.statusBarHidden {
                self.viewportYOffset += application.statusBarFrame.size.height
            }
        }
    }
    
    private var desiredItemSize: CGSize!
    private var needsBorderUpdate = false
    private var numberOfColumns = 1

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.desiredItemSize = self.itemSize
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        // Static standard attributes.
        self.minimumLineSpacing = 0.0
        self.minimumInteritemSpacing = 0.0
        self.sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 50.0, right: 0.0)
        // Dynamic standard attributes.
        let availableWidth = self.collectionView!.frame.size.width
        let previousNumberOfColumns = self.numberOfColumns
        self.numberOfColumns = Int(availableWidth / self.desiredItemSize.width)
        assert(self.numberOfColumns > 0, "Desired item size is too big.")
        self.needsBorderUpdate = self.numberOfColumns != previousNumberOfColumns
        let numberOfColumns = CGFloat(self.numberOfColumns)
        let numberOfGutters = numberOfColumns - 1
        let availableCellWidth = availableWidth - (numberOfGutters * self.minimumInteritemSpacing)
        let dimension = floor(availableCellWidth / numberOfColumns)
        self.itemSize = CGSize(width: dimension, height: dimension)
        // Custom attributes.
        self.updateViewportYOffset()
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        var layoutAttributesCollection = super.layoutAttributesForElementsInRect(rect) as [CollectionViewTileLayoutAttributes]
        for layoutAttributes in layoutAttributesCollection {
            if layoutAttributes.representedElementCategory == .Cell {
                self.configureBordersForLayoutAttributes(layoutAttributes)
            }
        }
        return layoutAttributesCollection
    }
    
    private func configureBordersForLayoutAttributes(layoutAttributes: CollectionViewTileLayoutAttributes)
    {
        let numberOfSectionItems = self.collectionView!.numberOfItemsInSection(layoutAttributes.indexPath.section)
        let itemIndex = layoutAttributes.indexPath.item
        let lastItemIndex = numberOfSectionItems - 1
        let lastRowItemIndex = self.numberOfColumns - 1
        let bottomEdgeStartIndex = max(lastItemIndex - self.numberOfColumns, 0)
        let rowItemIndex = itemIndex % self.numberOfColumns
        let remainingRowItemCount = lastRowItemIndex - rowItemIndex
        
        let isBottomEdgeCell = itemIndex > bottomEdgeStartIndex
        let isOnPartialLastRow = itemIndex + remainingRowItemCount > lastItemIndex
        let isOnRowWithBottomEdgeCell = !isBottomEdgeCell && (itemIndex + remainingRowItemCount > bottomEdgeStartIndex)
        let isSingleRowCell = numberOfSectionItems <= self.numberOfColumns
        let isTopEdgeCell = itemIndex < self.numberOfColumns
        
        if rowItemIndex == lastRowItemIndex {
            layoutAttributes.borderSizes.right = 0.0
        }
        if isBottomEdgeCell || isOnRowWithBottomEdgeCell || (isTopEdgeCell && isSingleRowCell) {
            layoutAttributes.borderSizes.bottom = 1.0
        }
        if isOnPartialLastRow && !isOnRowWithBottomEdgeCell && !isSingleRowCell {
            layoutAttributes.borderSizes.top = 0.0
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
    
    // MARK: ZoomTransitionControllerDelegate

    private var originalCellBorderSizes: UIEdgeInsets!

    func zoomTransitionController(transitionController: ZoomTransitionController,
        willCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)
    {
        if let cell = snapshotReferenceView as? CollectionViewTileCell {
            self.originalCellBorderSizes = cell.borderSizes
            cell.borderSizes = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
        }
    }
    
    func zoomTransitionController(transitionController: ZoomTransitionController,
        didCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)
    {
        if let cell = snapshotReferenceView as? CollectionViewTileCell {
            cell.borderSizes = self.originalCellBorderSizes
        }
    }
    
}

@objc(ETCollectionViewTileLayoutAttributes) class CollectionViewTileLayoutAttributes: UICollectionViewLayoutAttributes {
    
    var borderSizes = UIEdgeInsets(top: 1.0, left: 0.0, bottom: 0.0, right: 1.0)
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as CollectionViewTileLayoutAttributes
        copy.borderSizes = self.borderSizes
        return copy
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        var isEqual = super.isEqual(object)
        if isEqual {
            if let layoutAttributes = object as? CollectionViewTileLayoutAttributes {
                isEqual = UIEdgeInsetsEqualToEdgeInsets(layoutAttributes.borderSizes, self.borderSizes)
            }
        }
        return isEqual
    }
    
}