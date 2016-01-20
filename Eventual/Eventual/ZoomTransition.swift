//
//  ZoomTransitionController.swift
//  Eventual
//
//  Created by Peng Wang on 7/20/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import QuartzCore

class ZoomTransition: NSObject, AnimatedTransition {

    private(set) weak var delegate: TransitionAnimationDelegate!

    var animationOptions: UIViewAnimationOptions = [.CurveEaseInOut]
    var transitionDelay: NSTimeInterval = 0.0

    /**
     This can be customized, but it will default to the destination view controller's final frame.
     */
    var zoomedInFrame: CGRect?
    /**
     This is a zero-rect by default, but setting to the frame of the source view controller's
     triggering view, for example a cell view, is suggested.
     */
    var zoomedOutFrame = CGRectZero

    init(delegate: TransitionAnimationDelegate) {
        super.init()
        self.delegate = delegate
    }

    private func createSnapshotViewFromReferenceView(reference: UIView) -> UIView {
        self.delegate.animatedTransition(self, willCreateSnapshotViewFromReferenceView: reference)
        let snapshot = reference.snapshotViewAfterScreenUpdates(true)
        self.delegate.animatedTransition(self, didCreateSnapshotViewFromReferenceView: reference)
        return snapshot
    }

    private func unpackTransitionContext(transitionContext: UIViewControllerContextTransitioning) ->
                                        (UIViewController, UIViewController, UIView)
    {
        guard let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
                  toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
                  containerView = transitionContext.containerView()
              else { fatalError("Missing values in transitionContext.") }

        return (fromViewController, toViewController, containerView)
    }

    // MARK: UIViewControllerAnimatedTransitioning

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {}

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }

}

class ZoomInTransition: ZoomTransition {

    override init(delegate: TransitionAnimationDelegate) {
        super.init(delegate: delegate)
        self.transitionDelay = 0.3
    }

    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let (fromViewController, toViewController, containerView) = self.unpackTransitionContext(transitionContext)

        // Decide values.
        let initialAlpha: CGFloat = 0.0
        let initialFrame = self.zoomedOutFrame
        let initialScale: CGFloat = 0.01

        let finalAlpha: CGFloat = 1.0
        let finalFrame = self.zoomedInFrame ?? transitionContext.finalFrameForViewController(fromViewController)
        let finalScale: CGFloat = 1.0

        // Setup views.
        let presentedView = toViewController.view
        presentedView.frame = finalFrame
        let snapshotView = self.createSnapshotViewFromReferenceView(presentedView)
        snapshotView.frame = initialFrame
        snapshotView.frame.size.height = finalFrame.size.height * (initialFrame.size.width / finalFrame.size.width)
        snapshotView.alpha = initialAlpha
        containerView.addSubview(snapshotView)

        // Animate views.
        snapshotView.layer.transform = CATransform3DMakeScale(1.0, 1.0, initialScale)
        UIView.animateWithDuration( self.transitionDuration(transitionContext), delay: self.transitionDelay,
            options: self.animationOptions,
            animations: {
                snapshotView.alpha = finalAlpha
                snapshotView.frame = finalFrame
                snapshotView.layer.transform = CATransform3DMakeScale(1.0, 1.0, finalScale)
            }, completion: { finished in
                if finished {
                    containerView.addSubview(presentedView)
                    snapshotView.removeFromSuperview()
                }
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            }
        )
    }

}

class ZoomOutTransition: ZoomTransition {

    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let (fromViewController, toViewController, containerView) = self.unpackTransitionContext(transitionContext)

        // Decide values.
        let initialAlpha: CGFloat = 1.0
        let initialFrame = self.zoomedInFrame ?? transitionContext.finalFrameForViewController(toViewController)
        let initialScale: CGFloat = 1.0

        let finalAlpha: CGFloat = 0.0
        let finalFrame = self.zoomedOutFrame
        let finalScale: CGFloat = 0.01

        // Setup views.
        let presentedView = fromViewController.view
        let referenceView = self.delegate.animatedTransition(self, snapshotReferenceViewWhenReversed: true)
        let snapshotView = self.createSnapshotViewFromReferenceView(referenceView)
        snapshotView.frame = initialFrame
        snapshotView.frame.size.height = finalFrame.size.height * (initialFrame.size.width / finalFrame.size.width)
        snapshotView.alpha = initialAlpha
        containerView.addSubview(snapshotView)
        presentedView.removeFromSuperview()

        // Animate views.
        snapshotView.layer.transform = CATransform3DMakeScale(1.0, 1.0, initialScale)
        UIView.animateWithDuration( self.transitionDuration(transitionContext), delay: self.transitionDelay,
            options: self.animationOptions,
            animations: {
                snapshotView.alpha = finalAlpha
                snapshotView.frame = finalFrame
                snapshotView.layer.transform = CATransform3DMakeScale(1.0, 1.0, finalScale)
            }, completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            }
        )
    }

}
