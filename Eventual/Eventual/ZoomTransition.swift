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
        self.delegate.animatedTransition?(self, willCreateSnapshotViewFromReferenceView: reference)
        let snapshot = reference.snapshotViewAfterScreenUpdates(true)
        self.delegate.animatedTransition?(self, didCreateSnapshotViewFromReferenceView: reference)
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
        return 0.5
    }

}

class ZoomInTransition: ZoomTransition {

    override init(delegate: TransitionAnimationDelegate) {
        super.init(delegate: delegate)
        self.transitionDelay = 0.3
    }

    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let (fromViewController, toViewController, containerView) = self.unpackTransitionContext(transitionContext)

        let zoomedInFrame = self.zoomedInFrame ?? transitionContext.finalFrameForViewController(fromViewController)
        let zoomedInView = toViewController.view
        zoomedInView.frame = zoomedInFrame
        let zoomedInSnapshot = self.createSnapshotViewFromReferenceView(zoomedInView)

        let zoomedOutView = self.delegate.animatedTransition(self, snapshotReferenceViewWhenReversed: false)
        let zoomedOutSnapshot = self.createSnapshotViewFromReferenceView(zoomedOutView)

        containerView.addSubview(zoomedOutSnapshot)
        containerView.addSubview(zoomedInSnapshot)

        zoomedOutSnapshot.frame = self.zoomedOutFrame

        let largerDimension = max(zoomedInFrame.width, zoomedInFrame.height)
        let zoomedOutScale = 1.0 / (largerDimension / self.zoomedOutFrame.width)

        zoomedInSnapshot.alpha = 0.0
        zoomedInSnapshot.frame = self.zoomedOutFrame
        zoomedInSnapshot.frame.size.width *= (zoomedInFrame.width / largerDimension)
        zoomedInSnapshot.frame.size.height *= (zoomedInFrame.height / largerDimension)
        zoomedInSnapshot.frame.offsetInPlace(
            // Account for aspect ratio difference by shrinking to fit zoomedOutFrame.
            dx: (self.zoomedOutFrame.width - zoomedInSnapshot.frame.width) / 2.0,
            dy: (self.zoomedOutFrame.height - zoomedInSnapshot.frame.height) / 2.0
        )
        zoomedInSnapshot.layer.transform = CATransform3DMakeScale(1.0, 1.0, zoomedOutScale)

        zoomedOutSnapshot.frame = self.zoomedOutFrame
        zoomedOutSnapshot.layer.transform = CATransform3DMakeScale(1.0, 1.0, zoomedOutScale)

        self.delegate.animatedTransition?(self, willTransitionWithSnapshotReferenceView: zoomedOutView, reversed: false)
        UIView.animateWithDuration( self.transitionDuration(transitionContext),
            delay: self.transitionDelay,
            options: self.animationOptions,
            animations: {
                zoomedInSnapshot.alpha = 1.0
                zoomedInSnapshot.frame = zoomedInFrame
                zoomedInSnapshot.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)

                zoomedOutSnapshot.frame = zoomedInFrame
                zoomedOutSnapshot.frame.insetInPlace(
                    // Account for aspect ratio difference by expanding to fit zoomedInFrame.
                    dx: (zoomedOutSnapshot.frame.width - largerDimension) / 2.0,
                    dy: (zoomedOutSnapshot.frame.height - largerDimension) / 2.0
                )
                zoomedInSnapshot.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
            },
            completion: { finished in
                if finished {
                    containerView.addSubview(zoomedInView)
                    zoomedInSnapshot.removeFromSuperview()
                    zoomedOutSnapshot.removeFromSuperview()
                }
                self.delegate.animatedTransition?(self, didTransitionWithSnapshotReferenceView: zoomedOutView, reversed: false)
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            }
        )
    }

}

class ZoomOutTransition: ZoomTransition {

    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let (fromViewController, toViewController, containerView) = self.unpackTransitionContext(transitionContext)

        let zoomedInView = fromViewController.view
        let zoomedInSnapshot = self.createSnapshotViewFromReferenceView(zoomedInView)
        containerView.addSubview(zoomedInSnapshot)
        zoomedInView.removeFromSuperview()

        let zoomedOutView = self.delegate.animatedTransition(self, snapshotReferenceViewWhenReversed: true)
        let zoomedOutSnapshot = self.createSnapshotViewFromReferenceView(zoomedOutView)
        containerView.addSubview(zoomedOutSnapshot)

        let zoomedInFrame = self.zoomedInFrame ?? transitionContext.finalFrameForViewController(toViewController)
        let largerDimension = max(zoomedInFrame.width, zoomedInFrame.height)
        let zoomedOutScale = 1.0 / (largerDimension / self.zoomedOutFrame.width)

        zoomedInSnapshot.frame = zoomedInFrame
        zoomedInSnapshot.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)

        zoomedOutSnapshot.alpha = 0.0
        zoomedOutSnapshot.frame = zoomedInFrame
        zoomedOutSnapshot.frame.insetInPlace(
            // Account for aspect ratio difference by expanding to fit zoomedInFrame.
            dx: (zoomedOutSnapshot.frame.width - largerDimension) / 2.0,
            dy: (zoomedOutSnapshot.frame.height - largerDimension) / 2.0
        )
        zoomedOutSnapshot.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)

        self.delegate.animatedTransition?(self, willTransitionWithSnapshotReferenceView: zoomedOutView, reversed: true)
        UIView.animateWithDuration( self.transitionDuration(transitionContext) * 0.6,
            delay: self.transitionDelay,
            options: self.animationOptions,
            animations: {
                zoomedOutSnapshot.alpha = 1.0
            },
            completion: nil
        )
        UIView.animateWithDuration( self.transitionDuration(transitionContext), delay: self.transitionDelay,
            options: self.animationOptions,
            animations: {
                zoomedInSnapshot.frame = self.zoomedOutFrame
                zoomedInSnapshot.frame.size.width *= (zoomedInFrame.width / largerDimension)
                zoomedInSnapshot.frame.size.height *= (zoomedInFrame.height / largerDimension)
                zoomedInSnapshot.frame.offsetInPlace(
                    // Account for aspect ratio difference by shrinking to fit zoomedOutFrame.
                    dx: (self.zoomedOutFrame.width - zoomedInSnapshot.frame.width) / 2.0,
                    dy: (self.zoomedOutFrame.height - zoomedInSnapshot.frame.height) / 2.0
                )
                zoomedInSnapshot.layer.transform = CATransform3DMakeScale(1.0, 1.0, zoomedOutScale)

                zoomedOutSnapshot.frame = self.zoomedOutFrame
                zoomedOutSnapshot.layer.transform = CATransform3DMakeScale(1.0, 1.0, zoomedOutScale)
            },
            completion: { finished in
                if finished {
                    zoomedInSnapshot.removeFromSuperview()
                    zoomedOutSnapshot.removeFromSuperview()
                }
                self.delegate.animatedTransition?(self, didTransitionWithSnapshotReferenceView: zoomedOutView, reversed: true)
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            }
        )
    }

}
