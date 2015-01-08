//
//  TransitioningDelegate.swift
//  Eventual
//
//  Created by Peng Wang on 12/20/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

@objc(ETTransitionAnimationDelegate) protocol TransitionAnimationDelegate: class, NSObjectProtocol {

    func transitionSnapshotReferenceView(reversed: Bool) -> UIView
    
    func transitionWillCreateSnapshotViewFromSnapshotReferenceView(snapshotReferenceView: UIView)
    
    func transitionDidCreateSnapshotViewFromSnapshotReferenceView(snapshotReferenceView: UIView)
    
}

@objc(ETTransitionInteractionDelegate) protocol TransitionInteractionDelegate: class, NSObjectProtocol {

    func interactiveTransition(transition: InteractiveTransition,
         windowForGestureRecognizer recognizer: UIGestureRecognizer) -> UIWindow

    func interactiveTransition(transition: InteractiveTransition,
         locationContextViewForGestureRecognizer recognizer: UIGestureRecognizer) -> UIView

    func interactiveTransition(transition: InteractiveTransition,
         snapshotReferenceViewAtLocation location: CGPoint, ofContextView contextView: UIView) -> UIView?

}

@objc(ETInteractiveTransition) protocol InteractiveTransition: class, UIViewControllerInteractiveTransitioning {

    func setUp()
    func tearDown()

}

@objc(ETTransitioningDelegate) class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    weak var animationDelegate: TransitionAnimationDelegate!
    weak var interactionDelegate: TransitionInteractionDelegate!

    var isInteractive = false
    private var interactionController: InteractiveTransition?

    init(animationDelegate: TransitionAnimationDelegate,
         interactionDelegate: AnyObject? = nil,
         sourceViewController: UIViewController? = nil)
    {
        super.init()
        self.animationDelegate = animationDelegate
        if let delegate = interactionDelegate as? TransitionInteractionDelegate {
            self.interactionDelegate = delegate
            var source: UIViewController!
            if let viewController = sourceViewController {
                source = viewController
            } else if let delegate = interactionDelegate as? UIViewController {
                source = delegate
            } else {
                fatalError("Source view controller required.")
            }
            self.initInteractionControllerForSourceController(source)
        }
    }

    func setUp() {
        self.setUpInteractionController()
    }

    func tearDown() {
        self.tearDownInteractionController()
    }

    private func initInteractionControllerForSourceController(source: UIViewController) {
        if let collectionViewController = source as? UICollectionViewController {
            let zoomTransition = InteractiveZoomTransition(delegate: self.interactionDelegate)
            self.interactionController = zoomTransition
        }
        self.isInteractive = self.interactionController != nil
    }

    private func setUpInteractionController() {
        if let interactionController = self.interactionController {
            interactionController.setUp()
        }
    }

    private func tearDownInteractionController() {
        if let interactionController = self.interactionController {
            interactionController.tearDown()
        }
    }

    // MARK: - UIViewControllerTransitioningDelegate

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController,
         sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        var animationController: UIViewControllerAnimatedTransitioning?
        if let collectionViewController = source as? UICollectionViewController {
            let zoomTransition = AnimatedZoomTransition(delegate: self.animationDelegate)
            let offset = collectionViewController.collectionView!.contentOffset
            let cell = self.animationDelegate.transitionSnapshotReferenceView(false)
            zoomTransition.outFrame = CGRectOffset(cell.frame, -offset.x, -offset.y)
            animationController = zoomTransition
        }
        return animationController
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        var animationController: UIViewControllerAnimatedTransitioning?
        var source = dismissed.presentingViewController
        if let navigationController = source as? UINavigationController {
            source = navigationController.topViewController
        }
        if let collectionViewController = source as? UICollectionViewController {
            let zoomTransition = AnimatedZoomTransition(delegate: self.animationDelegate)
            let offset = collectionViewController.collectionView!.contentOffset
            let cell = self.animationDelegate.transitionSnapshotReferenceView(true)
            zoomTransition.outFrame = CGRectOffset(cell.frame, -offset.x, -offset.y)
            zoomTransition.isReversed = true
            animationController = zoomTransition
        }
        return animationController
    }

    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if !self.isInteractive { return nil }
        return self.interactionController
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if !self.isInteractive { return nil }
        return self.interactionController
    }
    
}
