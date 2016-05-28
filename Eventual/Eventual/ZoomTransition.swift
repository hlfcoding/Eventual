//
//  ZoomTransitionController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
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

    var transitionDelay: NSTimeInterval = 0
    /**
     This can be customized, but it will default to the destination view controller's final frame.
     */
    var zoomedInFrame = CGRectZero
    /**
     This is a zero-rect by default, but setting to the frame of the source view controller's
     triggering view, for example a cell view, is suggested.
     */
    var zoomedOutFrame = CGRectZero

    var zoomedOutReferenceViewBorderWidth: CGFloat = 1

    private weak var transitionContext: UIViewControllerContextTransitioning?

    private weak var zoomedInView: UIView!
    private weak var zoomedOutView: UIView!

    private weak var zoomedInViewController: UIViewController!
    private weak var zoomedOutViewController: UIViewController!

    private var zoomedInSnapshot: UIView!
    private var zoomedOutSnapshot: UIView!

    private var zoomedInCenter: CGPoint!
    private var zoomedOutCenter: CGPoint!

    private var zoomedInSubviews: [UIView]?
    private var zoomedOutSubviews: [UIView]?

    private var zoomedInSubviewSnapshots: [UIView]?
    private var zoomedOutSubviewSnapshots: [UIView]?

    private var usesSingleSubview: Bool {
        return self.zoomedOutSubviews?.count == 1 && self.zoomedInSubviews == nil
    }

    private var aspectFittingScale: CGFloat {
        return min(
            self.zoomedOutFrame.width / self.zoomedInFrame.width,
            self.zoomedOutFrame.height / self.zoomedInFrame.height
        )
    }
    /**
     Does an aspect-fit expand based on `zoomedInFrame`. Does not perform centering.
     Exposed for testing.
     */
    var aspectFittingZoomedOutFrameOfZoomedInSize: CGRect {
        var frame = CGRectApplyAffineTransform(
            self.zoomedInFrame,
            CGAffineTransformMakeScale(
                (self.zoomedOutFrame.width / self.aspectFittingScale) / self.zoomedInFrame.width,
                (self.zoomedOutFrame.height / self.aspectFittingScale) / self.zoomedInFrame.height
            )
        )
        // Account for borders.
        let outset = -self.zoomedOutReferenceViewBorderWidth
        frame.insetInPlace(dx: outset, dy: outset)
        return frame
    }

    /**
     Does an aspect-fit shrink based on `zoomedOutFrame`. Does not perform centering.
     Exposed for testing.
     */
    var aspectFittingZoomedInFrameOfZoomedOutSize: CGRect {
        return CGRectApplyAffineTransform(
            self.zoomedOutFrame,
            CGAffineTransformMakeScale(
                (self.zoomedInFrame.width * self.aspectFittingScale) / self.zoomedOutFrame.width,
                (self.zoomedInFrame.height * self.aspectFittingScale) / self.zoomedOutFrame.height
            )
        )
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
        snapshot.frame = frame.offsetBy(dx: superviewFrame.minX, dy: superviewFrame.minY)
        return snapshot
    }

    private func unpackTransitionContext() -> (UIViewController, UIViewController, UIView, UIViewControllerContextTransitioning) {
        guard
            let transitionContext = self.transitionContext,
            let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
            let containerView = transitionContext.containerView()
            else { fatalError("Missing transitionContext or its values.") }

        return (fromViewController, toViewController, containerView, transitionContext)
    }

    private func setUpReversed(reversed: Bool) {
        let (_, _, _, transitionContext) = self.unpackTransitionContext()

        self.zoomedInView = self.zoomedInViewController.view
        if self.zoomedInFrame == CGRectZero {
            self.zoomedInFrame = transitionContext.finalFrameForViewController(self.zoomedOutViewController)
        }

        self.zoomedOutView = self.delegate.animatedTransition(
            self, snapshotReferenceViewWhenReversed: reversed
        )

        self.zoomedOutSubviews = self.delegate.animatedTransition?(
            self, subviewsToAnimateSeparatelyForReferenceView: self.zoomedOutView
        )

        if let sources = self.zoomedOutSubviews {
            var destinations = [UIView]()
            sources.forEach {
                guard
                    let subview = self.delegate.animatedTransition?(
                        self, subviewInDestinationViewController: self.zoomedInViewController, forSubview: $0
                    )
                    else { return }
                destinations.append(subview)
            }
            if !destinations.isEmpty {
                self.zoomedInSubviews = destinations
            }
        }
    }

    private func addSnapshots() {
        let (_, _, containerView, _) = self.unpackTransitionContext()

        self.zoomedInSubviews?.forEach { $0.alpha = 0 }
        self.zoomedInSnapshot = self.createSnapshotViewFromReferenceView(self.zoomedInView)
        self.zoomedInSubviews?.forEach { $0.alpha = 1 }

        self.zoomedOutSnapshot = self.createSnapshotViewFromReferenceView(self.zoomedOutView)

        self.zoomedInSubviewSnapshots = self.zoomedInSubviews?.enumerate().map {
            let snapshot = self.createSnapshotViewFromReferenceSubview($1, ofViewWithFrame: self.zoomedInFrame)
            if let subview = $1.subviews.first as? UITextView {
                snapshot.frame.offsetInPlace(
                    dx: subview.textContainer.lineFragmentPadding, // Guessing.
                    dy: subview.layoutMargins.top + subview.contentInset.top  // Guessing.
                )
            } else if let zoomedOutSubview = self.zoomedOutSubviews?[$0] {
                // It's more important the subview content lines up.
                snapshot.frame.offsetInPlace(
                    dx: $1.layoutMargins.left - zoomedOutSubview.layoutMargins.left, // Guessing.
                    dy: $1.layoutMargins.top - zoomedOutSubview.layoutMargins.top  // Guessing.
                )
            }
            return snapshot
        }

        self.zoomedOutSubviewSnapshots = self.zoomedOutSubviews?.map {
            return self.createSnapshotViewFromReferenceSubview($0, ofViewWithFrame: self.zoomedOutFrame)
        }

        // Add subview snapshots first to avoid chance of redraws before all snapshots are added,
        // which can cause flickering since the zoomed-in snapshot is taken with its subviews hidden.
        if let zoomedOutSnapshots = self.zoomedOutSubviewSnapshots where !zoomedOutSnapshots.isEmpty {
            zoomedOutSnapshots.forEach { containerView.addSubview($0) }
            containerView.insertSubview(self.zoomedInSnapshot, belowSubview: zoomedOutSnapshots.first!)
        } else {
            containerView.addSubview(self.zoomedInSnapshot)
        }
        containerView.insertSubview(self.zoomedOutSnapshot, belowSubview: self.zoomedInSnapshot)
    }

    // MARK: UIViewControllerAnimatedTransitioning

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.4 + self.transitionDelay
    }

    // MARK: Animation Steps

    private func setUp() { fatalError("Unimplemented method.") }
    private func start() { fatalError("Unimplemented method.") }
    private func finish() { fatalError("Unimplemented method.") }
    private func tearDown(finished: Bool) { fatalError("Unimplemented method.") }
}

final class ZoomInTransition: ZoomTransition {

    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(transitionContext)

        let (fromViewController, toViewController, _, _) = self.unpackTransitionContext()
        self.zoomedOutViewController = fromViewController
        self.zoomedInViewController = toViewController

        dispatch_after(self.transitionDelay) {
            self.setUp()
            self.start()

            if self.usesSingleSubview, let snapshotView = self.zoomedOutSubviewSnapshots?.first {
                UIView.animateWithDuration(
                    0.5 * self.transitionDuration(transitionContext), delay: 0, options: [.CurveLinear],
                    animations: { snapshotView.alpha = 0 },
                    completion: nil
                )
            }

            UIView.animateWithDuration(
                self.transitionDuration(transitionContext), delay: 0, options: [],
                animations: { self.finish() },
                completion: { self.tearDown($0) }
            )
        }
    }

    override private func setUp() {
        self.setUpReversed(false)
        self.addSnapshots()
    }

    override private func start() {
        self.zoomedInView.frame = self.zoomedInFrame
        self.zoomedInCenter = self.zoomedInView.center

        self.zoomedOutSnapshot.frame = self.zoomedOutFrame
        self.zoomedOutCenter = self.zoomedOutSnapshot.center

        if self.zoomedInSubviews?.count > 0 {
            self.zoomedInView.layoutIfNeeded()
        }

        self.zoomedInSnapshot.alpha = 0
        self.zoomedInSnapshot.frame = self.aspectFittingZoomedInFrameOfZoomedOutSize
        self.zoomedInSnapshot.center = self.zoomedOutCenter

        self.delegate.animatedTransition?(
            self, willTransitionWithSnapshotReferenceView: self.zoomedOutView, reversed: false
        )
    }

    override private func finish() {
        self.zoomedInSnapshot.alpha = 1
        self.zoomedInSnapshot.frame = self.zoomedInFrame

        let expandedFrame = self.aspectFittingZoomedOutFrameOfZoomedInSize
        self.zoomedOutSnapshot.frame = expandedFrame
        self.zoomedOutSnapshot.center = self.zoomedInCenter

        if let destinations = self.zoomedInSubviewSnapshots where !destinations.isEmpty {
            for (index, destination) in destinations.enumerate() {
                guard let source = self.zoomedOutSubviewSnapshots?[index] else { continue }
                source.frame.origin = destination.frame.origin
            }

        } else if self.usesSingleSubview, let snapshotView = self.zoomedOutSubviewSnapshots?.first {
            snapshotView.frame = expandedFrame
            snapshotView.center = self.zoomedInCenter
        }
    }

    override private func tearDown(finished: Bool) {
        let (_, _, containerView, transitionContext) = self.unpackTransitionContext()

        if finished {
            containerView.subviews.forEach { $0.removeFromSuperview() }
            containerView.addSubview(self.zoomedInView)
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())

        self.delegate.animatedTransition?(
            self, didTransitionWithSnapshotReferenceView: self.zoomedOutView, reversed: false
        )
    }

}

final class ZoomOutTransition: ZoomTransition {

    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(transitionContext)

        let (fromViewController, toViewController, _, _) = self.unpackTransitionContext()
        self.zoomedInViewController = fromViewController
        self.zoomedOutViewController = toViewController

        dispatch_after(self.transitionDelay) {
            self.setUp()
            self.start()

            UIView.animateWithDuration(
                self.transitionDuration(transitionContext) * 0.6, delay: 0, options: [],
                animations: {
                    self.zoomedInSnapshot.alpha = 0
                    self.zoomedOutSnapshot.alpha = 1
                },
                completion: nil
            )
            UIView.animateWithDuration(
                self.transitionDuration(transitionContext), delay: 0, options: [],
                animations: { self.finish() },
                completion: { self.tearDown($0) }
            )
        }
    }

    private override func setUp() {
        self.setUpReversed(true)
        self.addSnapshots()
    }

    private override func start() {
        self.zoomedInCenter = self.zoomedInView.center

        self.zoomedInSnapshot.frame = self.zoomedInFrame

        self.zoomedOutSnapshot.alpha = 0
        self.zoomedOutSnapshot.frame = self.aspectFittingZoomedOutFrameOfZoomedInSize
        self.zoomedOutSnapshot.center = self.zoomedInCenter

        if let destinations = self.zoomedInSubviewSnapshots where !destinations.isEmpty {
            for (index, destination) in destinations.enumerate() {
                guard let source = self.zoomedOutSubviewSnapshots?[index] else { continue }
                source.frame.origin = destination.frame.origin
            }

        } else if self.usesSingleSubview, let snapshotView = self.zoomedOutSubviewSnapshots?.first {
            snapshotView.removeFromSuperview()
        }

        self.zoomedInView.removeFromSuperview()

        self.delegate.animatedTransition?(
            self, willTransitionWithSnapshotReferenceView: self.zoomedOutView, reversed: true
        )
    }

    private override func finish() {
        self.zoomedInSnapshot.frame = self.aspectFittingZoomedInFrameOfZoomedOutSize
        self.zoomedOutSnapshot.frame = self.zoomedOutFrame
        self.zoomedInSnapshot.center = self.zoomedOutSnapshot.center

        if !self.usesSingleSubview, let sources = self.zoomedOutSubviewSnapshots where !sources.isEmpty {
            for (index, source) in sources.enumerate() {
                guard let subview = self.zoomedOutSubviews?[index] else { continue }
                source.frame.origin = CGPointApplyAffineTransform(self.zoomedOutFrame.origin,
                    CGAffineTransformMakeTranslation(subview.frame.minX, subview.frame.minY)
                )
            }
        }
    }

    private override func tearDown(finished: Bool) {
        let (_, _, containerView, transitionContext) = self.unpackTransitionContext()

        if finished {
            containerView.subviews.forEach { $0.removeFromSuperview() }
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())

        self.delegate.animatedTransition?(
            self, didTransitionWithSnapshotReferenceView: self.zoomedOutView, reversed: true
        )
    }

}
