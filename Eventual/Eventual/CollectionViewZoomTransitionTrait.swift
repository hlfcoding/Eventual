//
//  CollectionViewZoomTransitionTrait.swift
//  Eventual
//
//  Created by Peng Wang on 12/20/14.
//  Copyright (c) 2014-2016 Eventual App. All rights reserved.
//

import UIKit

class CollectionViewZoomTransitionTrait: NSObject, UIViewControllerTransitioningDelegate {

    private(set) var collectionView: UICollectionView!

    private(set) weak var animationDelegate: TransitionAnimationDelegate!
    private(set) weak var interactionDelegate: TransitionInteractionDelegate!

    var isInteractive = false
    var isInteractionEnabled: Bool {
        get {
            return self.interactionController.isEnabled ?? false
        }
        set(newValue) {
            if let interactionController = self.interactionController {
                interactionController.isEnabled = newValue ?? false
            }
        }
    }
    private var interactionController: InteractiveZoomTransition!

    init(collectionView: UICollectionView,
         animationDelegate: TransitionAnimationDelegate,
         interactionDelegate: TransitionInteractionDelegate)
    {
        super.init()

        self.collectionView = collectionView
        self.animationDelegate = animationDelegate
        self.interactionDelegate = interactionDelegate

        self.initInteractionController()
    }

    private func initInteractionController() {
        guard let source = self.interactionDelegate as? UICollectionViewController
              else { assertionFailure("Source must be UICollectionViewController."); return }

        var reverseDelegate: TransitionInteractionDelegate?
        if let interactionDelegate = self.presentingViewControllerForViewController(source) as? TransitionInteractionDelegate {
            reverseDelegate = interactionDelegate
        }

        self.interactionController = InteractiveZoomTransition(delegate: self.interactionDelegate, reverseDelegate: reverseDelegate)
        self.interactionController.pinchWindow = UIApplication.sharedApplication().keyWindow!
        self.isInteractive = self.interactionController != nil
    }

    // MARK: - UIViewControllerTransitioningDelegate

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController,
         sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        let transition = ZoomInTransition(delegate: self.animationDelegate)

        let offset = self.collectionView.contentOffset
        let cell = self.animationDelegate.animatedTransition(transition, snapshotReferenceViewWhenReversed: false)
        transition.zoomedOutFrame = CGRectOffset(cell.frame, -offset.x, -offset.y)

        return transition
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let source = self.presentingViewControllerForViewController(dismissed) as? UICollectionViewController
              else { assertionFailure("Source must be UICollectionViewController."); return nil }

        let transition = ZoomOutTransition(delegate: self.animationDelegate)
        let offset = source.collectionView!.contentOffset
        let cell = self.animationDelegate.animatedTransition(transition, snapshotReferenceViewWhenReversed: true)
        transition.zoomedOutFrame = CGRectOffset(cell.frame, -offset.x, -offset.y)

        return transition
    }

    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard self.isInteractive else { return nil }
        return self.interactionController
    }

    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard self.isInteractive else { return nil }
        return self.interactionController
    }

    private func presentingViewControllerForViewController(viewController: UIViewController) -> UIViewController? {
        var presenting = viewController.presentingViewController
        if let navigationController = presenting as? UINavigationController {
            presenting = navigationController.topViewController
        }
        return presenting
    }

}
