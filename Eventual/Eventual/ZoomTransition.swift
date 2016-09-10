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

    var zoomedOutReferenceViewBorderWidth: CGFloat = 0

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
        return zoomedOutSubviews?.count == 1 && zoomedInSubviews == nil
    }

    private var aspectFittingScale: CGFloat {
        return min(
            (zoomedOutFrame.width - 2 * zoomedOutReferenceViewBorderWidth) / zoomedInFrame.width,
            (zoomedOutFrame.height - 2 * zoomedOutReferenceViewBorderWidth) / zoomedInFrame.height
        )
    }
    /**
     Does an aspect-fit expand based on `zoomedInFrame`. Does not perform centering.
     Exposed for testing.
     */
    var aspectFittingZoomedOutFrameOfZoomedInSize: CGRect {
        return CGRectApplyAffineTransform(
            zoomedInFrame,
            CGAffineTransformMakeScale(
                (zoomedOutFrame.width / aspectFittingScale) / zoomedInFrame.width,
                (zoomedOutFrame.height / aspectFittingScale) / zoomedInFrame.height
            )
        )
    }

    /**
     Does an aspect-fit shrink based on `zoomedOutFrame`. Does not perform centering.
     Exposed for testing.
     */
    var aspectFittingZoomedInFrameOfZoomedOutSize: CGRect {
        return CGRectApplyAffineTransform(
            zoomedOutFrame,
            CGAffineTransformMakeScale(
                (zoomedInFrame.width * aspectFittingScale) / zoomedOutFrame.width,
                (zoomedInFrame.height * aspectFittingScale) / zoomedOutFrame.height
            )
        )
    }

    init(delegate: TransitionAnimationDelegate) {
        super.init()
        self.delegate = delegate
    }

    private func createSnapshotViewFromReferenceView(reference: UIView) -> UIView {
        delegate.animatedTransition?(self, willCreateSnapshotViewFromReferenceView: reference)
        let snapshot = reference.snapshotViewAfterScreenUpdates(true)
        delegate.animatedTransition?(self, didCreateSnapshotView: snapshot, fromReferenceView: reference)
        return snapshot
    }

    private func createSnapshotViewFromReferenceSubview(reference: UIView,
                                                        ofViewWithFrame superviewFrame: CGRect) -> UIView {
        // Copy and restore frame in case snapshotting resets to frame to zero. This will happen
        // with views not yet presented.
        let frame = reference.frame
        let snapshot = reference.snapshotViewAfterScreenUpdates(true)
        reference.frame = frame
        snapshot.frame = frame.offsetBy(dx: superviewFrame.minX, dy: superviewFrame.minY)
        return snapshot
    }

    private func unpackTransitionContext() -> (UIViewController, UIViewController, UIView, UIViewControllerContextTransitioning) {
        guard let
            transitionContext = transitionContext,
            fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
            containerView = transitionContext.containerView()
            else { preconditionFailure("Missing transitionContext or its values.") }

        return (fromViewController, toViewController, containerView, transitionContext)
    }

    private func setUpReversed(reversed: Bool) {
        let (_, _, _, transitionContext) = unpackTransitionContext()

        zoomedInView = zoomedInViewController.view
        if zoomedInFrame == CGRectZero {
            zoomedInFrame = transitionContext.finalFrameForViewController(zoomedOutViewController)
        }

        zoomedOutView = delegate.animatedTransition(
            self, snapshotReferenceViewWhenReversed: reversed
        )

        zoomedOutSubviews = delegate.animatedTransition?(
            self, subviewsToAnimateSeparatelyForReferenceView: zoomedOutView
        )

        if let sources = self.zoomedOutSubviews {
            var destinations: [UIView] = []
            sources.forEach {
                guard
                    let subview = self.delegate.animatedTransition?(
                        self, subviewInDestinationViewController: self.zoomedInViewController, forSubview: $0
                    )
                    else { return }
                destinations.append(subview)
            }
            if !destinations.isEmpty {
                zoomedInSubviews = destinations
            }
        }
    }

    private func addSnapshots() {
        let (_, _, containerView, _) = unpackTransitionContext()

        zoomedInSubviews?.forEach { $0.alpha = 0 }
        zoomedInSnapshot = createSnapshotViewFromReferenceView(zoomedInView)
        zoomedInSubviews?.forEach { $0.alpha = 1 }

        zoomedOutSnapshot = createSnapshotViewFromReferenceView(zoomedOutView)

        zoomedInSubviewSnapshots = zoomedInSubviews?.enumerate().map {
            let snapshot = self.createSnapshotViewFromReferenceSubview($1, ofViewWithFrame: self.zoomedInFrame)
            if let subview = $1.subviews.first as? UITextView {
                snapshot.frame.offsetInPlace(
                    dx: subview.textContainer.lineFragmentPadding, // Guessing.
                    dy: subview.layoutMargins.top // Guessing.
                )
            } else if let zoomedOutSubview = self.zoomedOutSubviews?[$0] {
                // It's more important the subview content lines up.
                snapshot.frame.offsetInPlace(
                    dx: $1.layoutMargins.left - zoomedOutSubview.layoutMargins.left, // Guessing.
                    dy: $1.layoutMargins.top - zoomedOutSubview.layoutMargins.top // Guessing.
                )
            }
            return snapshot
        }

        zoomedOutSubviewSnapshots = zoomedOutSubviews?.map {
            return self.createSnapshotViewFromReferenceSubview($0, ofViewWithFrame: self.zoomedOutFrame)
        }

        // Add subview snapshots first to avoid chance of redraws before all snapshots are added,
        // which can cause flickering since the zoomed-in snapshot is taken with its subviews hidden.
        if let zoomedOutSnapshots = zoomedOutSubviewSnapshots where !zoomedOutSnapshots.isEmpty {
            zoomedOutSnapshots.forEach { containerView.addSubview($0) }
            containerView.insertSubview(zoomedInSnapshot, belowSubview: zoomedOutSnapshots.first!)
        } else {
            containerView.addSubview(zoomedInSnapshot)
        }
        containerView.insertSubview(zoomedOutSnapshot, belowSubview: zoomedInSnapshot)
    }

    // MARK: UIViewControllerAnimatedTransitioning

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.4 + transitionDelay
    }

    // MARK: Animation Steps

    private func setUp() {
        preconditionFailure("Unimplemented method.")
    }

    private func start() {
        preconditionFailure("Unimplemented method.")
    }

    private func finish() {
        preconditionFailure("Unimplemented method.")
    }

    private func tearDown(finished: Bool) {
        preconditionFailure("Unimplemented method.")
    }

}

final class ZoomInTransition: ZoomTransition {

    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(transitionContext)

        let (fromViewController, toViewController, _, _) = unpackTransitionContext()
        zoomedOutViewController = fromViewController
        zoomedInViewController = toViewController

        dispatchAfter(transitionDelay) {
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
        setUpReversed(false)
        addSnapshots()
    }

    override private func start() {
        zoomedInView.frame = zoomedInFrame
        zoomedInCenter = zoomedInView.center

        zoomedOutSnapshot.frame = zoomedOutFrame
        zoomedOutCenter = zoomedOutSnapshot.center

        if zoomedInSubviews?.count > 0 {
            zoomedInView.layoutIfNeeded()
        }

        zoomedInSnapshot.alpha = 0
        zoomedInSnapshot.frame = aspectFittingZoomedInFrameOfZoomedOutSize
        zoomedInSnapshot.center = zoomedOutCenter

        delegate.animatedTransition?(
            self, willTransitionWithSnapshotReferenceView: zoomedOutView, reversed: false
        )
    }

    override private func finish() {
        zoomedInSnapshot.alpha = 1
        zoomedInSnapshot.frame = zoomedInFrame

        let expandedFrame = aspectFittingZoomedOutFrameOfZoomedInSize
        zoomedOutSnapshot.frame = expandedFrame
        zoomedOutSnapshot.center = zoomedInCenter

        if let destinations = zoomedInSubviewSnapshots where !destinations.isEmpty {
            for (index, destination) in destinations.enumerate() {
                guard let source = self.zoomedOutSubviewSnapshots?[index] else { continue }
                source.frame.origin = destination.frame.origin
            }

        } else if usesSingleSubview, let snapshotView = zoomedOutSubviewSnapshots?.first {
            snapshotView.frame = expandedFrame
            snapshotView.center = zoomedInCenter
        }
    }

    override private func tearDown(finished: Bool) {
        let (_, _, containerView, transitionContext) = unpackTransitionContext()

        if finished {
            containerView.subviews.forEach { $0.removeFromSuperview() }
            containerView.addSubview(zoomedInView)
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())

        delegate.animatedTransition?(
            self, didTransitionWithSnapshotReferenceView: zoomedOutView, reversed: false
        )
    }

}

final class ZoomOutTransition: ZoomTransition {

    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(transitionContext)

        let (fromViewController, toViewController, _, _) = unpackTransitionContext()
        zoomedInViewController = fromViewController
        zoomedOutViewController = toViewController

        dispatchAfter(transitionDelay) {
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
        setUpReversed(true)
        addSnapshots()
    }

    private override func start() {
        zoomedInCenter = zoomedInView.center

        zoomedInSnapshot.frame = zoomedInFrame

        zoomedOutSnapshot.alpha = 0
        zoomedOutSnapshot.frame = aspectFittingZoomedOutFrameOfZoomedInSize
        zoomedOutSnapshot.center = zoomedInCenter

        if let destinations = zoomedInSubviewSnapshots where !destinations.isEmpty {
            for (index, destination) in destinations.enumerate() {
                guard let source = self.zoomedOutSubviewSnapshots?[index] else { continue }
                source.frame.origin = destination.frame.origin
            }

        } else if usesSingleSubview, let snapshotView = zoomedOutSubviewSnapshots?.first {
            snapshotView.removeFromSuperview()
        }

        zoomedInView.removeFromSuperview()

        delegate.animatedTransition?(
            self, willTransitionWithSnapshotReferenceView: zoomedOutView, reversed: true
        )
    }

    private override func finish() {
        zoomedInSnapshot.frame = aspectFittingZoomedInFrameOfZoomedOutSize
        zoomedOutSnapshot.frame = zoomedOutFrame
        zoomedInSnapshot.center = zoomedOutSnapshot.center

        if !usesSingleSubview, let sources = zoomedOutSubviewSnapshots where !sources.isEmpty {
            for (index, source) in sources.enumerate() {
                guard let subview = self.zoomedOutSubviews?[index] else { continue }
                source.frame.origin = CGPointApplyAffineTransform(self.zoomedOutFrame.origin,
                    CGAffineTransformMakeTranslation(
                        subview.frame.minX + zoomedOutReferenceViewBorderWidth,
                        subview.frame.minY + zoomedOutReferenceViewBorderWidth
                    )
                )
            }
        }
    }

    private override func tearDown(finished: Bool) {
        let (_, _, containerView, transitionContext) = unpackTransitionContext()

        if finished {
            containerView.subviews.forEach { $0.removeFromSuperview() }
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())

        delegate.animatedTransition?(
            self, didTransitionWithSnapshotReferenceView: zoomedOutView, reversed: true
        )
    }

}
