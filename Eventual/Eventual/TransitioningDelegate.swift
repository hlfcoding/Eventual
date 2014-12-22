//
//  TransitioningDelegate.swift
//  Eventual
//
//  Created by Peng Wang on 12/20/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

@objc(ETTransitionAnimationDelegate) protocol TransitionAnimationDelegate: NSObjectProtocol {

    func transitionSnapshotReferenceView(reversed: Bool) -> UIView
    
    func transitionWillCreateSnapshotViewFromSnapshotReferenceView(snapshotReferenceView: UIView)
    
    func transitionDidCreateSnapshotViewFromSnapshotReferenceView(snapshotReferenceView: UIView)
    
}

@objc(ETTransitioningDelegate) class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    weak var animationDelegate: TransitionAnimationDelegate!

    init(animationDelegate: TransitionAnimationDelegate) {
        super.init()
        self.animationDelegate = animationDelegate
    }

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

    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning!) -> UIViewControllerInteractiveTransitioning! {
        return nil
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning!) -> UIViewControllerInteractiveTransitioning! {
        return nil
    }
    
}
