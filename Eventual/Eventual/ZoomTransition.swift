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
    var zoomedInFrame = CGRectZero

    var zoomedInFrameLargerDimension: CGFloat { return max(zoomedInFrame.width, zoomedInFrame.height) }

    /**
     This is a zero-rect by default, but setting to the frame of the source view controller's
     triggering view, for example a cell view, is suggested.
     */
    var zoomedOutFrame = CGRectZero

    var zoomedOutScale: CGFloat { return 1.0 / (self.zoomedInFrameLargerDimension / self.zoomedOutFrame.width) }

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

    private func expandZoomedOutFramePerZoomedInFrame(frame: CGRect) -> CGRect {
        let newFrame = frame.insetBy(
            // Account for aspect ratio difference by expanding to fit zoomedInFrame.
            dx: (frame.width - self.zoomedInFrameLargerDimension) / 2.0,
            dy: (frame.height - self.zoomedInFrameLargerDimension) / 2.0
        )
        return newFrame
    }

    private func shrinkZoomedInFramePerZoomedOutFrame(frame: CGRect) -> CGRect {
        var newFrame = frame
        newFrame.size.width *= (self.zoomedInFrame.width / self.zoomedInFrameLargerDimension)
        newFrame.size.height *= (self.zoomedInFrame.height / self.zoomedInFrameLargerDimension)
        newFrame.offsetInPlace(
            // Account for aspect ratio difference by shrinking to fit zoomedOutFrame.
            dx: (self.zoomedOutFrame.width - newFrame.width) / 2.0,
            dy: (self.zoomedOutFrame.height - newFrame.height) / 2.0
        )
        return newFrame
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

        if self.zoomedInFrame == CGRectZero {
            self.zoomedInFrame = transitionContext.finalFrameForViewController(fromViewController)
        }

        let zoomedInView = toViewController.view
        zoomedInView.frame = self.zoomedInFrame
        let zoomedInSnapshot = self.createSnapshotViewFromReferenceView(zoomedInView)

        let zoomedOutView = self.delegate.animatedTransition(self, snapshotReferenceViewWhenReversed: false)
        let zoomedOutSnapshot = self.createSnapshotViewFromReferenceView(zoomedOutView)
        zoomedOutSnapshot.frame = self.zoomedOutFrame

        containerView.addSubview(zoomedOutSnapshot)
        containerView.addSubview(zoomedInSnapshot)

        zoomedInSnapshot.alpha = 0.0
        zoomedInSnapshot.frame = self.shrinkZoomedInFramePerZoomedOutFrame(self.zoomedOutFrame)

        zoomedOutSnapshot.frame = self.zoomedOutFrame

        self.delegate.animatedTransition?(self, willTransitionWithSnapshotReferenceView: zoomedOutView, reversed: false)
        UIView.animateWithDuration( self.transitionDuration(transitionContext),
            delay: self.transitionDelay,
            options: self.animationOptions,
            animations: {
                zoomedInSnapshot.alpha = 1.0
                zoomedInSnapshot.frame = self.zoomedInFrame
                zoomedOutSnapshot.frame = self.expandZoomedOutFramePerZoomedInFrame(self.zoomedInFrame)
            },
            completion: { finished in
                if finished {
                    containerView.subviews.forEach { $0.removeFromSuperview() }
                    containerView.addSubview(zoomedInView)
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

        if self.zoomedInFrame == CGRectZero {
            self.zoomedInFrame = transitionContext.finalFrameForViewController(toViewController)
        }

        let zoomedInView = fromViewController.view
        let zoomedInSnapshot = self.createSnapshotViewFromReferenceView(zoomedInView)
        containerView.addSubview(zoomedInSnapshot)
        zoomedInView.removeFromSuperview()

        let zoomedOutView = self.delegate.animatedTransition(self, snapshotReferenceViewWhenReversed: true)
        let zoomedOutSnapshot = self.createSnapshotViewFromReferenceView(zoomedOutView)
        containerView.addSubview(zoomedOutSnapshot)

        zoomedInSnapshot.frame = self.zoomedInFrame

        zoomedOutSnapshot.alpha = 0.0
        zoomedOutSnapshot.frame = self.expandZoomedOutFramePerZoomedInFrame(self.zoomedInFrame)

        self.delegate.animatedTransition?(self, willTransitionWithSnapshotReferenceView: zoomedOutView, reversed: true)
        UIView.animateWithDuration( self.transitionDuration(transitionContext) * 0.6,
            delay: self.transitionDelay,
            options: self.animationOptions,
            animations: { zoomedOutSnapshot.alpha = 1.0 },
            completion: nil
        )
        UIView.animateWithDuration( self.transitionDuration(transitionContext), delay: self.transitionDelay,
            options: self.animationOptions,
            animations: {
                zoomedInSnapshot.frame = self.shrinkZoomedInFramePerZoomedOutFrame(self.zoomedOutFrame)
                zoomedOutSnapshot.frame = self.zoomedOutFrame
            },
            completion: { finished in
                if finished {
                    containerView.subviews.forEach { $0.removeFromSuperview() }
                }
                self.delegate.animatedTransition?(self, didTransitionWithSnapshotReferenceView: zoomedOutView, reversed: true)
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            }
        )
    }

}
