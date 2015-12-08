//
//  TransitioningDelegate.swift
//  Eventual
//
//  Created by Peng Wang on 12/20/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

protocol TransitionAnimationDelegate: NSObjectProtocol {

    func animatedTransition(transition: AnimatedTransition,
         snapshotReferenceViewWhenReversed reversed: Bool) -> UIView

    func animatedTransition(transition: AnimatedTransition,
         willCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)

    func animatedTransition(transition: AnimatedTransition,
         didCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)

}

protocol TransitionInteractionDelegate: NSObjectProtocol {

    func interactiveTransition(transition: InteractiveTransition,
         windowForGestureRecognizer recognizer: UIGestureRecognizer) -> UIWindow

    func interactiveTransition(transition: InteractiveTransition,
         locationContextViewForGestureRecognizer recognizer: UIGestureRecognizer) -> UIView

    func interactiveTransition(transition: InteractiveTransition,
         snapshotReferenceViewAtLocation location: CGPoint, ofContextView contextView: UIView) -> UIView?

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)

    func beginInteractiveDismissalTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)

    func interactiveTransition(transition: InteractiveTransition,
         destinationScaleForSnapshotReferenceView referenceView: UIView?,
         contextView: UIView, reversed: Bool) -> CGFloat

}

protocol AnimatedTransition: UIViewControllerAnimatedTransitioning {}

protocol InteractiveTransition: UIViewControllerInteractiveTransitioning {

    var isEnabled: Bool { get set }

}

class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

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
            let source: UIViewController!
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
        if source is UICollectionViewController {
            var reverseDelegate: TransitionInteractionDelegate?
            if let interactionDelegate = self.presentingViewControllerForViewController(source) as? TransitionInteractionDelegate {
                reverseDelegate = interactionDelegate
            }
            let zoomTransition = InteractiveZoomTransition(delegate: self.interactionDelegate, reverseDelegate: reverseDelegate)
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
        let source = self.presentingViewControllerForViewController(dismissed)
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
        guard self.isInteractive else { print("BLOCKED"); return nil }
        return self.interactionController
    }

    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard self.isInteractive else { print("BLOCKED"); return nil }
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
