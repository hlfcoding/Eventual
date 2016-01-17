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

    private(set) var collectionView: UICollectionView!

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

}

protocol CollectionViewBackgroundTapTraitDelegate: NSObjectProtocol {

    func backgroundTapTraitDidToggleHighlight()

}

class CollectionViewBackgroundTapTrait: CollectionViewTrait {

    private(set) weak var delegate: CollectionViewBackgroundTapTraitDelegate!
    private(set) var highlightedColor: UIColor!
    private(set) var originalColor: UIColor!
    private(set) var tapRecognizer: UITapGestureRecognizer!
    private(set) var view: UIView!

    init(delegate: CollectionViewBackgroundTapTraitDelegate,
         collectionView: UICollectionView,
         tapRecognizer: UITapGestureRecognizer,
         highlightedColor: UIColor = UIColor(white: 0.0, alpha: 0.05))
    {
        super.init(collectionView: collectionView)

        self.delegate = delegate

        self.tapRecognizer = tapRecognizer
        self.tapRecognizer.addTarget(self, action: Selector("handleTap:"))
        self.collectionView.panGestureRecognizer.requireGestureRecognizerToFail(self.tapRecognizer)

        self.view = UIView()
        self.view.userInteractionEnabled = true
        self.view.addGestureRecognizer(self.tapRecognizer)
        self.collectionView.backgroundView = self.view

        self.highlightedColor = highlightedColor
        self.view.backgroundColor = UIColor.clearColor()
        self.originalColor = self.view.backgroundColor
        self.collectionView.backgroundColor = AppearanceManager.defaultManager.lightGrayColor

        self.view.isAccessibilityElement = true
        self.view.accessibilityLabel = Label.TappableBackground.rawValue
    }

    @IBAction func handleTap(sender: AnyObject) {
        UIView.animateKeyframesWithDuration( 0.4, delay: 0.0,
            options: [.BeginFromCurrentState, .CalculationModeCubic],
            animations: {
                UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.5) {
                    self.view.backgroundColor = self.highlightedColor
                }
                UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5) {
                    self.view.backgroundColor = self.originalColor
                }
            },
            completion: { finished in
                guard finished else { return }
                self.delegate.backgroundTapTraitDidToggleHighlight()
            }
        )
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
