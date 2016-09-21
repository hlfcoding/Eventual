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

    fileprivate(set) weak var delegate: TransitionAnimationDelegate!

    var transitionDelay: TimeInterval = 0
    /**
     This can be customized, but it will default to the destination view controller's final frame.
     */
    var zoomedInFrame: CGRect = .zero
    /**
     This is a zero-rect by default, but setting to the frame of the source view controller's
     triggering view, for example a cell view, is suggested.
     */
    var zoomedOutFrame: CGRect = .zero

    var zoomedOutReferenceViewBorderWidth: CGFloat = 0

    fileprivate weak var transitionContext: UIViewControllerContextTransitioning?

    fileprivate weak var zoomedInView: UIView!
    fileprivate weak var zoomedOutView: UIView!

    fileprivate weak var zoomedInViewController: UIViewController!
    fileprivate weak var zoomedOutViewController: UIViewController!

    fileprivate var zoomedInSnapshot: UIView!
    fileprivate var zoomedOutSnapshot: UIView!

    fileprivate var zoomedInCenter: CGPoint!
    fileprivate var zoomedOutCenter: CGPoint!

    fileprivate var zoomedInSubviews: [UIView]?
    fileprivate var zoomedOutSubviews: [UIView]?

    fileprivate var zoomedInSubviewSnapshots: [UIView]?
    fileprivate var zoomedOutSubviewSnapshots: [UIView]?

    fileprivate var usesSingleSubview: Bool {
        return zoomedOutSubviews?.count == 1 && zoomedInSubviews == nil
    }

    fileprivate var aspectFittingScale: CGFloat {
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
        return zoomedInFrame.applying(CGAffineTransform(
            scaleX: (zoomedOutFrame.width / aspectFittingScale) / zoomedInFrame.width,
            y: (zoomedOutFrame.height / aspectFittingScale) / zoomedInFrame.height
        ))
    }

    /**
     Does an aspect-fit shrink based on `zoomedOutFrame`. Does not perform centering.
     Exposed for testing.
     */
    var aspectFittingZoomedInFrameOfZoomedOutSize: CGRect {
        return zoomedOutFrame.applying(CGAffineTransform(
            scaleX: (zoomedInFrame.width * aspectFittingScale) / zoomedOutFrame.width,
            y: (zoomedInFrame.height * aspectFittingScale) / zoomedOutFrame.height
        ))
    }

    init(delegate: TransitionAnimationDelegate) {
        super.init()
        self.delegate = delegate
    }

    fileprivate func createSnapshotView(from referenceView: UIView) -> UIView {
        delegate.animatedTransition?(self, willCreateSnapshotViewFromReferenceView: referenceView)
        let snapshot = referenceView.snapshotView(afterScreenUpdates: true)
        delegate.animatedTransition?(self, didCreateSnapshotView: snapshot!, fromReferenceView: referenceView)
        return snapshot!
    }

    fileprivate func createSnapshotView(from referenceSubview: UIView,
                                    ofViewWithFrame superviewFrame: CGRect) -> UIView {
        // Copy and restore frame in case snapshotting resets to frame to zero. This will happen
        // with views not yet presented.
        let frame = referenceSubview.frame
        let snapshot = referenceSubview.snapshotView(afterScreenUpdates: true)
        referenceSubview.frame = frame
        snapshot!.frame = frame.offsetBy(dx: superviewFrame.minX, dy: superviewFrame.minY)
        return snapshot!
    }

    fileprivate func unpackTransitionContext() ->
        (UIViewController, UIViewController, UIView, UIViewControllerContextTransitioning) {
        guard let transitionContext = transitionContext,
            let fromViewController = transitionContext.viewController(forKey: .from),
            let toViewController = transitionContext.viewController(forKey: .to)
            else { preconditionFailure("Missing transitionContext or its values.") }

        return (fromViewController, toViewController, transitionContext.containerView, transitionContext)
    }

    fileprivate func setUp(reversed: Bool) {
        let (_, _, _, transitionContext) = unpackTransitionContext()

        zoomedInView = zoomedInViewController.view
        if zoomedInFrame == .zero {
            zoomedInFrame = transitionContext.finalFrame(for: zoomedOutViewController)
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

    fileprivate func addSnapshots() {
        let (_, _, containerView, _) = unpackTransitionContext()

        zoomedInSubviews?.forEach { $0.alpha = 0 }
        zoomedInSnapshot = createSnapshotView(from: zoomedInView)
        zoomedInSubviews?.forEach { $0.alpha = 1 }

        zoomedOutSnapshot = createSnapshotView(from: zoomedOutView)

        zoomedInSubviewSnapshots = zoomedInSubviews?.enumerated().map {
            let snapshot = self.createSnapshotView(from: $1, ofViewWithFrame: self.zoomedInFrame)
            if let subview = $1.subviews.first as? UITextView {
                snapshot.frame = snapshot.frame.offsetBy(
                    dx: subview.textContainer.lineFragmentPadding, // Guessing.
                    dy: subview.layoutMargins.top // Guessing.
                )
            } else if let zoomedOutSubview = self.zoomedOutSubviews?[$0] {
                // It's more important the subview content lines up.
                snapshot.frame = snapshot.frame.offsetBy(
                    dx: $1.layoutMargins.left - zoomedOutSubview.layoutMargins.left, // Guessing.
                    dy: $1.layoutMargins.top - zoomedOutSubview.layoutMargins.top // Guessing.
                )
            }
            return snapshot
        }

        zoomedOutSubviewSnapshots = zoomedOutSubviews?.map {
            return self.createSnapshotView(from: $0, ofViewWithFrame: self.zoomedOutFrame)
        }

        // Add subview snapshots first to avoid chance of redraws before all snapshots are added,
        // which can cause flickering since the zoomed-in snapshot is taken with its subviews hidden.
        if let zoomedOutSnapshots = zoomedOutSubviewSnapshots, !zoomedOutSnapshots.isEmpty {
            zoomedOutSnapshots.forEach { containerView.addSubview($0) }
            containerView.insertSubview(zoomedInSnapshot, belowSubview: zoomedOutSnapshots.first!)
        } else {
            containerView.addSubview(zoomedInSnapshot)
        }
        containerView.insertSubview(zoomedOutSnapshot, belowSubview: zoomedInSnapshot)
    }

    // MARK: UIViewControllerAnimatedTransitioning

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4 + transitionDelay
    }

    // MARK: Animation Steps

    fileprivate func setUp() {
        preconditionFailure("Unimplemented method.")
    }

    fileprivate func start() {
        preconditionFailure("Unimplemented method.")
    }

    fileprivate func finish() {
        preconditionFailure("Unimplemented method.")
    }

    fileprivate func tearDown(finished: Bool) {
        preconditionFailure("Unimplemented method.")
    }

}

final class ZoomInTransition: ZoomTransition {

    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(using: transitionContext)

        let (fromViewController, toViewController, _, _) = unpackTransitionContext()
        zoomedOutViewController = fromViewController
        zoomedInViewController = toViewController

        dispatchAfter(transitionDelay) {
            self.setUp()
            self.start()

            if self.usesSingleSubview, let snapshotView = self.zoomedOutSubviewSnapshots?.first {
                UIView.animate(
                    withDuration: 0.5 * self.transitionDuration(using: transitionContext),
                    delay: 0, options: .curveLinear,
                    animations: { snapshotView.alpha = 0 },
                    completion: nil
                )
            }

            UIView.animate(
                withDuration: self.transitionDuration(using: transitionContext),
                animations: { self.finish() },
                completion: { self.tearDown(finished: $0) }
            )
        }
    }

    override fileprivate func setUp() {
        setUp(reversed: false)
        addSnapshots()
    }

    override fileprivate func start() {
        zoomedInView.frame = zoomedInFrame
        zoomedInCenter = zoomedInView.center

        zoomedOutSnapshot.frame = zoomedOutFrame
        zoomedOutCenter = zoomedOutSnapshot.center

        if let count = zoomedInSubviews?.count, count > 0 {
            zoomedInView.layoutIfNeeded()
        }

        zoomedInSnapshot.alpha = 0
        zoomedInSnapshot.frame = aspectFittingZoomedInFrameOfZoomedOutSize
        zoomedInSnapshot.center = zoomedOutCenter

        delegate.animatedTransition?(
            self, willTransitionWithSnapshotReferenceView: zoomedOutView, reversed: false
        )
    }

    override fileprivate func finish() {
        zoomedInSnapshot.alpha = 1
        zoomedInSnapshot.frame = zoomedInFrame

        let expandedFrame = aspectFittingZoomedOutFrameOfZoomedInSize
        zoomedOutSnapshot.frame = expandedFrame
        zoomedOutSnapshot.center = zoomedInCenter

        if let destinations = zoomedInSubviewSnapshots, !destinations.isEmpty {
            for (index, destination) in destinations.enumerated() {
                guard let source = self.zoomedOutSubviewSnapshots?[index] else { continue }
                source.frame.origin = destination.frame.origin
            }

        } else if usesSingleSubview, let snapshotView = zoomedOutSubviewSnapshots?.first {
            snapshotView.frame = expandedFrame
            snapshotView.center = zoomedInCenter
        }
    }

    override fileprivate func tearDown(finished: Bool) {
        let (fromViewController, toViewController, containerView, transitionContext) = unpackTransitionContext()

        if finished {
            containerView.subviews.forEach { $0.removeFromSuperview() }
            containerView.addSubview(zoomedInView)
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

        delegate.animatedTransition?(
            self, didTransitionWithSnapshotReferenceView: zoomedOutView,
            fromViewController: fromViewController, toViewController: toViewController, reversed: false
        )
    }

}

final class ZoomOutTransition: ZoomTransition {

    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(using: transitionContext)

        let (fromViewController, toViewController, _, _) = unpackTransitionContext()
        zoomedInViewController = fromViewController
        zoomedOutViewController = toViewController

        dispatchAfter(transitionDelay) {
            self.setUp()
            self.start()

            UIView.animate(
                withDuration: self.transitionDuration(using: transitionContext) * 0.6,
                animations: {
                    self.zoomedInSnapshot.alpha = 0
                    self.zoomedOutSnapshot.alpha = 1
                },
                completion: nil
            )
            UIView.animate(
                withDuration: self.transitionDuration(using: transitionContext),
                animations: { self.finish() },
                completion: { self.tearDown(finished: $0) }
            )
        }
    }

    override fileprivate func setUp() {
        setUp(reversed: true)
        addSnapshots()
    }

    override fileprivate func start() {
        zoomedInCenter = zoomedInView.center

        zoomedInSnapshot.frame = zoomedInFrame

        zoomedOutSnapshot.alpha = 0
        zoomedOutSnapshot.frame = aspectFittingZoomedOutFrameOfZoomedInSize
        zoomedOutSnapshot.center = zoomedInCenter

        if let destinations = zoomedInSubviewSnapshots, !destinations.isEmpty {
            for (index, destination) in destinations.enumerated() {
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

    override fileprivate func finish() {
        zoomedInSnapshot.frame = aspectFittingZoomedInFrameOfZoomedOutSize
        zoomedOutSnapshot.frame = zoomedOutFrame
        zoomedInSnapshot.center = zoomedOutSnapshot.center

        if !usesSingleSubview, let sources = zoomedOutSubviewSnapshots, !sources.isEmpty {
            for (index, source) in sources.enumerated() {
                guard let subview = self.zoomedOutSubviews?[index] else { continue }
                source.frame.origin = self.zoomedOutFrame.origin.applying(CGAffineTransform(
                    translationX: subview.frame.minX + zoomedOutReferenceViewBorderWidth,
                    y: subview.frame.minY + zoomedOutReferenceViewBorderWidth
                ))
            }
        }
    }

    override fileprivate func tearDown(finished: Bool) {
        let (fromViewController, toViewController, containerView, transitionContext) = unpackTransitionContext()

        if finished {
            containerView.subviews.forEach { $0.removeFromSuperview() }
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

        delegate.animatedTransition?(
            self, didTransitionWithSnapshotReferenceView: zoomedOutView,
            fromViewController: fromViewController, toViewController: toViewController, reversed: true
        )
    }

}
