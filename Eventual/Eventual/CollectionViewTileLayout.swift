//
//  CollectionViewTileLayout.swift
//  Eventual
//
//  Created by Peng Wang on 10/11/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

@objc(ETCollectionViewTileLayout) class CollectionViewTileLayout: UICollectionViewFlowLayout {
    
    var viewportYOffset: CGFloat = 0.0
    
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
        if let navigationController = UIApplication.sharedApplication().keyWindow.rootViewController as? UINavigationController {
            self.viewportYOffset = UIApplication.sharedApplication().statusBarFrame.size.height +
                                   navigationController.navigationBar.frame.size.height
        }
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
            layoutAttributes.borderRightWidth = 0.0
        }
        if isBottomEdgeCell || isOnRowWithBottomEdgeCell || (isTopEdgeCell && isSingleRowCell) {
            layoutAttributes.borderBottomWidth = 1.0
        }
        if isOnPartialLastRow && !isOnRowWithBottomEdgeCell && !isSingleRowCell {
            layoutAttributes.borderTopWidth = 0.0
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

@objc(ETCollectionViewTileLayoutAttributes) class CollectionViewTileLayoutAttributes: UICollectionViewLayoutAttributes {
    
    var borderTopWidth: CGFloat = 1.0
    var borderLeftWidth: CGFloat = 0.0
    var borderBottomWidth: CGFloat = 0.0
    var borderRightWidth: CGFloat = 1.0
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as CollectionViewTileLayoutAttributes
        copy.borderTopWidth = self.borderTopWidth
        copy.borderLeftWidth = self.borderLeftWidth
        copy.borderBottomWidth = self.borderBottomWidth
        copy.borderRightWidth = self.borderRightWidth
        return copy
    }
    
}