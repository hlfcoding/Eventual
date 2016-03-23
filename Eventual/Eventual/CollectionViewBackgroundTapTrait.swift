//
//  CollectionViewBackgroundTapTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol CollectionViewBackgroundTapTraitDelegate: NSObjectProtocol {

    var collectionView: UICollectionView? { get set }
    var backgroundTapRecognizer: UITapGestureRecognizer! { get }

    func backgroundTapTraitDidToggleHighlight()

}

let CollectionViewBackgroundTapDuration: NSTimeInterval = 0.3

class CollectionViewBackgroundTapTrait {

    private(set) weak var delegate: CollectionViewBackgroundTapTraitDelegate!

    private var collectionView: UICollectionView! { return self.delegate.collectionView! }
    private var tapRecognizer: UITapGestureRecognizer! { return self.delegate.backgroundTapRecognizer }

    private(set) var highlightedColor: UIColor = UIColor(white: 0.0, alpha: 0.05)
    private(set) var originalColor: UIColor!
    private(set) var view: UIView!

    init(delegate: CollectionViewBackgroundTapTraitDelegate) {
        self.delegate = delegate

        self.tapRecognizer.addTarget(self, action: #selector(CollectionViewBackgroundTapTrait.handleTap(_:)))
        self.collectionView.panGestureRecognizer.requireGestureRecognizerToFail(self.tapRecognizer)

        self.view = UIView()
        self.view.userInteractionEnabled = true
        self.view.addGestureRecognizer(self.tapRecognizer)
        self.collectionView.backgroundView = self.view

        self.view.backgroundColor = UIColor.clearColor()
        self.originalColor = self.collectionView.backgroundColor

        self.view.isAccessibilityElement = true
        self.view.accessibilityLabel = Label.TappableBackground.rawValue
    }

    /**
     Call this in `viewDidAppear:` and `viewWillDisappear:` if `reverse` is on.
     */
    func updateOnAppearance(animated: Bool, reverse: Bool = false) {
        let update = {
            self.collectionView.backgroundColor = reverse ? self.originalColor : AppearanceManager.defaultManager.lightGrayColor
        }
        if animated {
            UIView.animateWithDuration(
                CollectionViewBackgroundTapDuration, delay: 0.0,
                options: [.BeginFromCurrentState], animations: update, completion: nil
            )
        } else {
            update()
        }
    }

    @objc @IBAction func handleTap(sender: AnyObject) {
        UIView.animateKeyframesWithDuration(
            CollectionViewBackgroundTapDuration, delay: 0.0,
            options: [.BeginFromCurrentState, .CalculationModeCubic],
            animations: {
                UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.5) {
                    self.view.backgroundColor = self.highlightedColor
                }
                UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5) {
                    self.view.backgroundColor = UIColor.clearColor()
                }
            },
            completion: { finished in
                guard finished else { return }
                self.delegate.backgroundTapTraitDidToggleHighlight()
            }
        )
    }

}
