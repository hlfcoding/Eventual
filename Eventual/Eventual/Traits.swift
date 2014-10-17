//
//  Traits.swift
//  Eventual
//
//  Created by Peng Wang on 10/18/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

struct CollectionViewInteractiveBackgroundViewTrait {
    
    var highlightedColor: UIColor!
    var originalColor: UIColor!
    var tapRecognizer: UITapGestureRecognizer!
    
    private var collectionView: UICollectionView!
    private var view: UIView!
    
    init(collectionView:UICollectionView,
         tapRecognizer: UITapGestureRecognizer,
         highlightedColor: UIColor = UIColor(white: 0.0, alpha: 0.05))
    {
        self.tapRecognizer = tapRecognizer
        self.highlightedColor = highlightedColor
        self.originalColor = UIColor.clearColor()

        self.collectionView = collectionView
    }
    
    mutating func setUp() {
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