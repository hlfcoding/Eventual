//
//  CollectionViewTileLayout.swift
//  Eventual
//
//  Created by Peng Wang on 10/11/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETCollectionViewTileLayout) class CollectionViewTileLayout: UICollectionViewFlowLayout {
    
    var viewportYOffset: CGFloat = 0.0
    
    private var desiredItemSize: CGSize!
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
        self.numberOfColumns = Int(availableWidth / self.desiredItemSize.width)
        assert(self.numberOfColumns > 0, "Desired item size is too big.")
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
    
    func borderInsetsForDefaultBorderInsets(defaultInsets: UIEdgeInsets,
         numberOfSectionItems: Int, atIndexPath indexPath:NSIndexPath) -> UIEdgeInsets
    {
        var borderInsets = defaultInsets
        
        let itemIndex = indexPath.item
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
            borderInsets.right = 0.0
        }
        if isBottomEdgeCell || isOnRowWithBottomEdgeCell || (isTopEdgeCell && isSingleRowCell) {
            borderInsets.bottom = 1.0
        }
        if isOnPartialLastRow && !isOnRowWithBottomEdgeCell && !isSingleRowCell {
            borderInsets.top = 0.0
        }
        
        return borderInsets
        
    }
    
}