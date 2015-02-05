//
//  TransitioningDelegate.swift
//  Eventual
//
//  Created by Peng Wang on 12/20/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

@objc(ETTransitionAnimationDelegate) protocol TransitionAnimationDelegate: class, NSObjectProtocol {

    func animatedTransition(transition: AnimatedTransition,
         snapshotReferenceViewWhenReversed reversed: Bool) -> UIView
    
    func animatedTransition(transition: AnimatedTransition,
         willCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)
    
    func animatedTransition(transition: AnimatedTransition,
         didCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)
    
}

@objc(ETTransitionInteractionDelegate) protocol TransitionInteractionDelegate: class, NSObjectProtocol {

    func interactiveTransition(transition: InteractiveTransition,
         windowForGestureRecognizer recognizer: UIGestureRecognizer) -> UIWindow

    func interactiveTransition(transition: InteractiveTransition,
         locationContextViewForGestureRecognizer recognizer: UIGestureRecognizer) -> UIView

    func interactiveTransition(transition: InteractiveTransition,
         snapshotReferenceViewAtLocation location: CGPoint, ofContextView contextView: UIView) -> UIView?

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)

    optional func beginInteractiveDismissalTransition(transition: InteractiveTransition,
                  withSnapshotReferenceView referenceView: UIView?)

    optional func interactiveTransition(transition: InteractiveTransition,
                  destinationScaleForSnapshotReferenceView referenceView: UIView?, contextView: UIView) -> CGFloat

}

@objc(ETAnimatedTransition) protocol AnimatedTransition: class, UIViewControllerAnimatedTransitioning {}

@objc(ETInteractiveTransition) protocol InteractiveTransition: class, UIViewControllerInteractiveTransitioning {

    var isEnabled: Bool { get set }

}

@objc(ETTransitioningDelegate) class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    weak var animationDelegate: TransitionAnimationDelegate!
    weak var interactionDelegate: TransitionInteractionDelegate!

    var isInteractive = false
    var isInteractionEnabled: Bool {
        get {
            return self.interactionController?.isEnabled ?? false
        }
        set(newValue) {
            if let interactionController = self.interactionController {
                interactionController.isEnabled = newValue ?? false
            }
        }
    }
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

    private func initInteractionControllerForSourceController(source: UIViewController) {
        if let collectionViewController = source as? UICollectionViewController {
            let zoomTransition = InteractiveZoomTransition(delegate: self.interactionDelegate)
            self.interactionController = zoomTransition
        }
        self.isInteractive = self.interactionController != nil
    }

    // MARK: - UIViewControllerTransitioningDelegate

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController,
         sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        var animationController: UIViewControllerAnimatedTransitioning?
        if let collectionViewController = source as? UICollectionViewController {
            let zoomTransition = AnimatedZoomTransition(delegate: self.animationDelegate)
            let offset = collectionViewController.collectionView!.contentOffset
            let cell = self.animationDelegate.animatedTransition(zoomTransition, snapshotReferenceViewWhenReversed: false)
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
            let cell = self.animationDelegate.animatedTransition(zoomTransition, snapshotReferenceViewWhenReversed: true)
            zoomTransition.outFrame = CGRectOffset(cell.frame, -offset.x, -offset.y)
            zoomTransition.isReversed = true
            animationController = zoomTransition
        }
        return animationController
    }

    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if !self.isInteractive { println("BLOCKED"); return nil }
        return self.interactionController
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if !self.isInteractive { println("BLOCKED"); return nil }
        return self.interactionController
    }
    
}
