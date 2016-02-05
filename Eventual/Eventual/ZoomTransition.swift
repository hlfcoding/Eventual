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

    var transitionDelay: NSTimeInterval = 0.0

    /**
     This can be customized, but it will default to the destination view controller's final frame.
     */
    var zoomedInFrame = CGRectZero

    private var zoomedInLargerDimension: CGFloat { return max(self.zoomedInFrame.width, self.zoomedInFrame.height) }

    /**
     This is a zero-rect by default, but setting to the frame of the source view controller's
     triggering view, for example a cell view, is suggested.
     */
    var zoomedOutFrame = CGRectZero

    var zoomedOutReferenceViewBorderWidth: CGFloat = 1.0
    private var zoomedOutScale: CGFloat {
        let zoomedOutDimension: CGFloat
        if self.zoomedInLargerDimension == self.zoomedInFrame.width {
            zoomedOutDimension = self.zoomedOutFrame.width
        } else {
            zoomedOutDimension = self.zoomedOutFrame.height
        }
        return 1.0 / (self.zoomedInLargerDimension / zoomedOutDimension)
    }

    init(delegate: TransitionAnimationDelegate) {
        super.init()
        self.delegate = delegate
    }

    private func createSnapshotViewFromReferenceView(reference: UIView) -> UIView {
        self.delegate.animatedTransition?(self, willCreateSnapshotViewFromReferenceView: reference)
        let snapshot = reference.snapshotViewAfterScreenUpdates(true)
        self.delegate.animatedTransition?(self, didCreateSnapshotView:snapshot, fromReferenceView: reference)
        return snapshot
    }

    private func expandZoomedOutFramePerZoomedInFrame(frame: CGRect) -> CGRect {
        // TODO: Delegate method for border size.
        let zoomedInBorderInset = ceil(self.zoomedOutReferenceViewBorderWidth / self.zoomedOutScale) + 1.0
        let newFrame = frame.insetBy(
            // Account for aspect ratio difference by expanding to fit zoomedInFrame.
            dx: floor((frame.width - self.zoomedInLargerDimension) / 2.0) - zoomedInBorderInset,
            dy: floor((frame.height - self.zoomedInLargerDimension) / 2.0) - zoomedInBorderInset
        )
        return newFrame
    }

    private func shrinkZoomedInFramePerZoomedOutFrame(frame: CGRect) -> CGRect {
        var newFrame = frame
        newFrame.size.width *= (self.zoomedInFrame.width / self.zoomedInLargerDimension)
        newFrame.size.height *= (self.zoomedInFrame.height / self.zoomedInLargerDimension)
        newFrame.offsetInPlace(
            // Account for aspect ratio difference by shrinking to fit zoomedOutFrame.
            dx: floor((self.zoomedOutFrame.width - newFrame.width) / 2.0),
            dy: floor((self.zoomedOutFrame.height - newFrame.height) / 2.0)
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

        var zoomedOutSubviewSnapshots = [UIView]()
        if let zoomedOutSubviews = self.delegate.animatedTransition?(self,
               subviewsToAnimateSeparatelyForReferenceView: zoomedOutView)
        {
            for subview in zoomedOutSubviews {
                let snapshot = subview.snapshotViewAfterScreenUpdates(true)
                snapshot.frame = subview.frame.offsetBy(
                    dx: zoomedOutSnapshot.frame.origin.x,
                    dy: zoomedOutSnapshot.frame.origin.y
                )
                zoomedOutSubviewSnapshots.append(snapshot)
            }
        }

        containerView.addSubview(zoomedOutSnapshot)
        zoomedOutSubviewSnapshots.forEach { containerView.addSubview($0) }
        containerView.addSubview(zoomedInSnapshot)

        zoomedInSnapshot.alpha = 0.0
        zoomedInSnapshot.frame = self.shrinkZoomedInFramePerZoomedOutFrame(self.zoomedOutFrame)

        self.delegate.animatedTransition?(self, willTransitionWithSnapshotReferenceView: zoomedOutView, reversed: false)
        UIView.animateWithDuration( 0.5 * self.transitionDuration(transitionContext),
            delay: self.transitionDelay,
            options: [.CurveLinear],
            animations: { zoomedOutSubviewSnapshots.forEach { $0.alpha = 0.0 } },
            completion: nil
        )
        UIView.animateWithDuration( self.transitionDuration(transitionContext),
            delay: self.transitionDelay,
            options: [.CurveEaseInOut],
            animations: {
                zoomedInSnapshot.alpha = 1.0
                zoomedInSnapshot.frame = self.zoomedInFrame

                let expandedFrame = self.expandZoomedOutFramePerZoomedInFrame(self.zoomedInFrame)
                zoomedOutSnapshot.frame = expandedFrame

                // TODO: This ain't right.
                zoomedOutSubviewSnapshots.forEach { $0.frame = expandedFrame }
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
            options: [.CurveEaseInOut],
            animations: { zoomedOutSnapshot.alpha = 1.0 },
            completion: nil
        )
        UIView.animateWithDuration( self.transitionDuration(transitionContext), delay: self.transitionDelay,
            options: [.CurveEaseInOut],
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
