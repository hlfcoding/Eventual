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
    func backgroundTapTraitFallbackBarButtonItem() -> UIBarButtonItem

}

let CollectionViewBackgroundTapDuration: NSTimeInterval = 0.3

class CollectionViewBackgroundTapTrait {

    var enabled: Bool {
        get { return tapRecognizer.enabled }
        set(newValue) {
            guard newValue != enabled else { return }
            tapRecognizer.enabled = newValue
            view.isAccessibilityElement = newValue
            view.userInteractionEnabled = newValue
            updateFallbackBarButtonItem()
        }
    }

    private(set) weak var delegate: CollectionViewBackgroundTapTraitDelegate!

    private var collectionView: UICollectionView! { return delegate.collectionView! }
    private var tapRecognizer: UITapGestureRecognizer! { return delegate.backgroundTapRecognizer }

    private(set) var highlightedColor: UIColor = UIColor(white: 0, alpha: 0.05)
    private(set) var originalColor: UIColor!
    private(set) var view: UIView!

    init(delegate: CollectionViewBackgroundTapTraitDelegate) {
        self.delegate = delegate

        tapRecognizer.addTarget(self, action: #selector(handleTap(_:)))
        collectionView.panGestureRecognizer.requireGestureRecognizerToFail(tapRecognizer)

        view = UIView()
        view.accessibilityLabel = a(.TappableBackground)
        view.addGestureRecognizer(tapRecognizer)
        collectionView.backgroundView = view

        view.backgroundColor = UIColor.clearColor()
        originalColor = collectionView.backgroundColor

        // Still need these here.
        view.userInteractionEnabled = true
        view.isAccessibilityElement = true
    }

    /**
     Call this in `viewDidAppear:` and `viewWillDisappear:` if `reverse` is on.
     */
    func updateOnAppearance(animated: Bool, reverse: Bool = false) {
        let update = {
            self.collectionView.backgroundColor = reverse ? self.originalColor : Appearance.lightGrayColor
        }
        if animated {
            UIView.animateWithDuration(CollectionViewBackgroundTapDuration, animations: update)
        } else {
            update()
        }
    }

    @objc @IBAction func handleTap(sender: AnyObject) {
        UIView.animateKeyframesWithDuration(
            CollectionViewBackgroundTapDuration, delay: 0,
            options: [.CalculationModeCubic],
            animations: {
                UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5) {
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

    /**
     Show fallback `UIBarButtonItem` if background tap is disabled and if trait is being used by a
     `UIViewController`. Animate toggling if view is visible.
     */
    private func updateFallbackBarButtonItem() {
        guard let viewController = self.delegate as? UIViewController else { return }
        let buttonItem: UIBarButtonItem? = self.enabled ?
            nil : self.delegate.backgroundTapTraitFallbackBarButtonItem()
        let isScreenVisible = self.collectionView.window != nil
        viewController.navigationItem.setRightBarButtonItem(buttonItem, animated: isScreenVisible)
    }
}
