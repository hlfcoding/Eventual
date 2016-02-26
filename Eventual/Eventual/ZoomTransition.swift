//
//  ZoomTransitionController.swift
//  Eventual
//
//  Created by Peng Wang on 7/20/14.
//  Copyright (c) 2014-2016 Eventual App. All rights reserved.
//

import UIKit
import QuartzCore

/**
 Note that because the image-backed snapshot views will scale their image according to their
 `frame`, only animating `frame` is enough and the expected `transform` animation isn't needed.
 Using frames is also simpler given we're animating from one reference view to another and don't
 need to calculate as many transforms.
 */
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

    private func createSnapshotViewFromReferenceSubview(reference: UIView,
                 ofViewWithFrame superviewFrame: CGRect) -> UIView
    {
        // Copy and restore frame in case snapshotting resets to frame to zero. This will happen
        // with views not yet presented.
        let frame = reference.frame
        let snapshot = reference.snapshotViewAfterScreenUpdates(true)
        reference.frame = frame
        snapshot.frame = frame.offsetBy(dx: superviewFrame.origin.x, dy: superviewFrame.origin.y)
        return snapshot
    }

    /** Does not perform centering. */
    private func expandZoomedOutFramePerZoomedInFrame(zoomedInFrame: CGRect) -> CGRect {
        var frame = CGRectApplyAffineTransform(zoomedInFrame, CGAffineTransformMakeScale(
            self.zoomedInLargerDimension / zoomedInFrame.width,
            self.zoomedInLargerDimension / zoomedInFrame.height
        ))
        // Account for borders.
        let outset = -self.zoomedOutReferenceViewBorderWidth
        frame.insetInPlace(dx: outset, dy: outset)
        return frame
    }

    /** Does not perform centering. */
    private func shrinkZoomedInFramePerZoomedOutFrame(zoomedOutFrame: CGRect) -> CGRect {
        return CGRectApplyAffineTransform(zoomedOutFrame, CGAffineTransformMakeScale(
            self.zoomedInFrame.width / self.zoomedInLargerDimension,
            self.zoomedInFrame.height / self.zoomedInLargerDimension
        ))
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
        let zoomedInCenter = zoomedInView.center

        let zoomedOutView = self.delegate.animatedTransition(self, snapshotReferenceViewWhenReversed: false)

        let zoomedOutSubviews = self.delegate.animatedTransition?(self,
            subviewsToAnimateSeparatelyForReferenceView: zoomedOutView) ?? []
        let zoomedOutSubviewSnapshots = zoomedOutSubviews.map {
            return self.createSnapshotViewFromReferenceSubview($0, ofViewWithFrame: self.zoomedOutFrame)
        }

        let zoomedOutSnapshot = self.createSnapshotViewFromReferenceView(zoomedOutView)
        zoomedOutSnapshot.frame = self.zoomedOutFrame
        let zoomedOutCenter = zoomedOutSnapshot.center

        var zoomedInSubviews = [UIView]()
        zoomedOutSubviews.forEach {
            if let subview = self.delegate.animatedTransition?(
                self, subviewInDestinationViewController: toViewController, forSubview: $0
            ) { zoomedInSubviews.append(subview) }
        }

        zoomedInSubviews.forEach { $0.alpha = 0.0 } // TODO: Temporary.
        let zoomedInSnapshot = self.createSnapshotViewFromReferenceView(zoomedInView)
        zoomedInSubviews.forEach { $0.alpha = 1.0 } // TODO: Temporary.

        if !zoomedInSubviews.isEmpty {
            zoomedInView.layoutIfNeeded()
        }
        let zoomedInSubviewSnapshots = zoomedInSubviews.map {
            let snapshot = self.createSnapshotViewFromReferenceSubview($0, ofViewWithFrame: self.zoomedInFrame)
            if let subview = $0.subviews.first as? UITextView {
                snapshot.frame.offsetInPlace(
                    dx: subview.textContainer.lineFragmentPadding, // Guessing.
                    dy: subview.layoutMargins.top + subview.contentInset.top  // Guessing.
                )
            }
            return snapshot
        } as [UIView]

        containerView.addSubview(zoomedOutSnapshot)
        containerView.addSubview(zoomedInSnapshot)
        zoomedOutSubviewSnapshots.forEach { containerView.addSubview($0) }

        zoomedInSnapshot.alpha = 0.0
        zoomedInSnapshot.frame = self.shrinkZoomedInFramePerZoomedOutFrame(self.zoomedOutFrame)
        zoomedInSnapshot.center = zoomedOutCenter

        self.delegate.animatedTransition?(self, willTransitionWithSnapshotReferenceView: zoomedOutView, reversed: false)
        UIView.animateWithDuration( 0.5 * self.transitionDuration(transitionContext),
            delay: self.transitionDelay,
            options: [.CurveLinear],
            animations: {
                if zoomedOutSubviewSnapshots.count == 1 {
                    zoomedOutSubviewSnapshots.first!.alpha = 0.0
                }
            },
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
                zoomedOutSnapshot.center = zoomedInCenter

                if !zoomedInSubviewSnapshots.isEmpty {
                    for (index, zoomedInSnapshot) in zoomedInSubviewSnapshots.enumerate() {
                        let zoomedOutSnapshot = zoomedOutSubviewSnapshots[index]
                        zoomedOutSnapshot.frame.origin = zoomedInSnapshot.frame.origin
                    }
                } else if zoomedOutSubviewSnapshots.count == 1 {
                    zoomedOutSubviewSnapshots.first!.frame = expandedFrame
                    zoomedOutSubviewSnapshots.first!.center = zoomedInCenter
                }
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
        let zoomedInCenter = zoomedInView.center
        let zoomedInSnapshot = self.createSnapshotViewFromReferenceView(zoomedInView)
        containerView.addSubview(zoomedInSnapshot)
        zoomedInView.removeFromSuperview()

        let zoomedOutView = self.delegate.animatedTransition(self, snapshotReferenceViewWhenReversed: true)
        let zoomedOutSnapshot = self.createSnapshotViewFromReferenceView(zoomedOutView)
        containerView.addSubview(zoomedOutSnapshot)

        zoomedInSnapshot.frame = self.zoomedInFrame

        zoomedOutSnapshot.alpha = 0.0
        zoomedOutSnapshot.frame = self.expandZoomedOutFramePerZoomedInFrame(self.zoomedInFrame)
        zoomedOutSnapshot.center = zoomedInCenter

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
                zoomedInSnapshot.center = zoomedOutSnapshot.center
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
