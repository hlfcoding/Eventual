//
//  Traits.swift
//  Eventual
//
//  Created by Peng Wang on 10/18/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import EventKit

@objc(ETCollectionViewTrait) class CollectionViewTrait {
    
    var collectionView: UICollectionView!
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    
}

@objc(ETCollectionViewInteractiveBackgroundViewTrait) class CollectionViewInteractiveBackgroundViewTrait: CollectionViewTrait {
    
    var highlightedColor: UIColor!
    var originalColor: UIColor!
    var tapRecognizer: UITapGestureRecognizer!
    
    private var view: UIView!
    
    init(collectionView: UICollectionView,
         tapRecognizer: UITapGestureRecognizer,
         highlightedColor: UIColor = UIColor(white: 0.0, alpha: 0.05))
    {
        super.init(collectionView: collectionView)
        self.tapRecognizer = tapRecognizer
        self.highlightedColor = highlightedColor
        self.originalColor = UIColor.clearColor()
    }
    
    func setUp() {
        self.view = UIView()
        self.view.backgroundColor = UIColor.clearColor()
        self.view.userInteractionEnabled = true
        self.view.addGestureRecognizer(self.tapRecognizer)
        self.collectionView.backgroundColor = AppearanceManager.defaultManager().lightGrayColor
        self.collectionView.backgroundView = self.view
        self.originalColor = self.view.backgroundColor
    }
    
    func toggleHighlighted(highlighted: Bool) {
        let newColor = highlighted ? self.highlightedColor : self.originalColor
        UIView.animateWithDuration( 0.2, delay: 0.0,
            options: .CurveEaseInOut | .BeginFromCurrentState,
            animations: { self.view.backgroundColor = newColor },
            completion: nil
        )
    }
    
    func handleTap() {
        self.toggleHighlighted(true)
    }
    
    func handleScrollViewWillEndDragging(scrollView: UIScrollView,
                                         withVelocity velocity: CGPoint,
                                         targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        self.toggleHighlighted(false)
    }

}

@objc(ETCollectionViewAutoReloadDataTrait) class CollectionViewAutoReloadDataTrait : CollectionViewTrait {
    
    func reloadFromEntityOperationNotification(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let type: EKEntityType = userInfo[ETEntityOperationNotificationTypeKey]! as! EKEntityType
        switch type {
        case EKEntityTypeEvent:
            self.collectionView.reloadData()
        default:
            fatalError("Unimplemented entity type.")
        }
    }
    
}