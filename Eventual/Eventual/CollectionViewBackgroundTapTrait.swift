//
//  CollectionViewBackgroundTapTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol CollectionViewBackgroundTapTraitDelegate: NSObjectProtocol {

    var collectionView: UICollectionView? { get }
    var backgroundFallbackHitAreaHeight: CGFloat { get }

    func backgroundTapTraitDidToggleHighlight(at location: CGPoint)
    func backgroundTapTraitFallbackBarButtonItem() -> UIBarButtonItem

}

extension CollectionViewBackgroundTapTraitDelegate {

    var backgroundFallbackHitAreaHeight: CGFloat { return 0 }

}

let CollectionViewBackgroundTapDuration: TimeInterval = 0.3

class CollectionViewBackgroundTapTrait {

    var isEnabled: Bool {
        get { return tapRecognizer.isEnabled }
        set {
            guard newValue != isEnabled else { return }
            tapRecognizer.isEnabled = newValue
            view.isAccessibilityElement = newValue
            view.isUserInteractionEnabled = newValue
            updateFallbackBarButtonItem()
            updateFallbackHitArea()
        }
    }

    private(set) weak var delegate: CollectionViewBackgroundTapTraitDelegate!

    private var collectionView: UICollectionView! { return delegate.collectionView! }
    private var tapRecognizer = UITapGestureRecognizer()

    private(set) var highlightedColor = UIColor(white: 0, alpha: 0.05)
    private(set) var originalColor: UIColor!
    private(set) var view: UIView!

    init(delegate: CollectionViewBackgroundTapTraitDelegate) {
        self.delegate = delegate

        tapRecognizer.addTarget(self, action: #selector(handleTap(sender:)))
        tapRecognizer.delaysTouchesBegan = true
        collectionView.panGestureRecognizer.require(toFail: tapRecognizer)

        view = UIView()
        view.accessibilityLabel = a(.tappableBackground)
        view.addGestureRecognizer(tapRecognizer)
        collectionView.backgroundView = view

        view.backgroundColor = UIColor.clear
        originalColor = collectionView.backgroundColor

        // Still need these here.
        view.isUserInteractionEnabled = true
        view.isAccessibilityElement = true

        updateFallbackHitArea()
    }

    /**
     Call this in `viewWillTransitionToSize:withTransitionCoordinator:`.
     */
    func updateFallbackHitArea() {
        collectionView.contentInset.bottom = self.delegate.backgroundFallbackHitAreaHeight
    }

    @objc func handleTap(sender: Any) {
        UIView.animateKeyframes(
            withDuration: CollectionViewBackgroundTapDuration, delay: 0,
            options: .calculationModeCubic,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                    self.view.backgroundColor = self.highlightedColor
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.view.backgroundColor = UIColor.clear
                }
            },
            completion: { finished in
                guard finished else { return }
                let location = self.tapRecognizer.location(in: self.delegate.collectionView)
                self.delegate.backgroundTapTraitDidToggleHighlight(at: location)
            }
        )
    }

    /**
     Show fallback `UIBarButtonItem` if background tap is disabled and if trait is being used by a
     `UIViewController`. Animate toggling if view is visible.
     */
    private func updateFallbackBarButtonItem() {
        guard let viewController = self.delegate as? UIViewController else { return }
        let buttonItem: UIBarButtonItem? = self.isEnabled ?
            nil : self.delegate.backgroundTapTraitFallbackBarButtonItem()
        let isScreenVisible = self.collectionView.window != nil
        viewController.navigationItem.setRightBarButton(buttonItem, animated: isScreenVisible)
    }

}
