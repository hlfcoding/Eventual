//
//  CollectionViewBackgroundTapTrait.swift
//  Eventual
//
//  Created by Peng Wang on 10/18/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

protocol CollectionViewBackgroundTapTraitDelegate: NSObjectProtocol {

    func backgroundTapTraitDidToggleHighlight()

}

class CollectionViewBackgroundTapTrait {

    private(set) weak var delegate: CollectionViewBackgroundTapTraitDelegate!
    private(set) var collectionView: UICollectionView!

    private(set) var highlightedColor: UIColor!
    private(set) var originalColor: UIColor!
    private(set) var tapRecognizer: UITapGestureRecognizer!
    private(set) var view: UIView!

    init(delegate: CollectionViewBackgroundTapTraitDelegate,
         collectionView: UICollectionView,
         tapRecognizer: UITapGestureRecognizer,
         highlightedColor: UIColor = UIColor(white: 0.0, alpha: 0.05))
    {
        self.delegate = delegate
        self.collectionView = collectionView

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
