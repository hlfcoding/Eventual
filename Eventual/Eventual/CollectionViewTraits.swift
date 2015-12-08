//
//  Traits.swift
//  Eventual
//
//  Created by Peng Wang on 10/18/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import EventKit

class CollectionViewTrait {

    var collectionView: UICollectionView { return self._collectionView }
    private var _collectionView: UICollectionView!

    init(collectionView: UICollectionView) {
        self._collectionView = collectionView
    }

}

class CollectionViewInteractiveBackgroundViewTrait: CollectionViewTrait {

    var highlightedColor: UIColor { return self._highlightedColor }
    var originalColor: UIColor { return self._originalColor }
    var tapRecognizer: UITapGestureRecognizer { return self._tapRecognizer }
    var view: UIView { return self._view }

    private var _highlightedColor: UIColor!
    private var _originalColor: UIColor = UIColor.clearColor()
    private var _tapRecognizer: UITapGestureRecognizer!
    private var _view: UIView!

    init(collectionView: UICollectionView,
         tapRecognizer: UITapGestureRecognizer,
         highlightedColor: UIColor = UIColor(white: 0.0, alpha: 0.05))
    {
        super.init(collectionView: collectionView)
        self._tapRecognizer = tapRecognizer
        self._highlightedColor = highlightedColor
    }

    func setUp() {
        self._view = UIView()
        self.view.backgroundColor = UIColor.clearColor()
        self.view.userInteractionEnabled = true
        self.view.addGestureRecognizer(self.tapRecognizer)
        self.view.isAccessibilityElement = true
        self.view.accessibilityLabel = Label.TappableBackground.rawValue
        self.collectionView.backgroundColor = AppearanceManager.defaultManager()?.lightGrayColor
        self.collectionView.backgroundView = self.view
        if let backgroundColor = self.view.backgroundColor {
            self._originalColor = backgroundColor
        }
    }

    func toggleHighlighted(highlighted: Bool) {
        let newColor = highlighted ? self.highlightedColor : self.originalColor
        UIView.animateWithDuration( 0.2, delay: 0.0,
            options: [.CurveEaseInOut, .BeginFromCurrentState],
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

class CollectionViewAutoReloadDataTrait: CollectionViewTrait {

    dynamic func reloadFromEntityOperationNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
                  // FIXME: This is pretty ugly, due to being forced to store raw value inside dict.
                  type = userInfo[TypeKey] as? UInt where type == EKEntityType.Event.rawValue
              else { return }
        self.collectionView.reloadData()
    }

}
