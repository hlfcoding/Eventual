//
//  ZoomTransitionController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import QuartzCore

enum ZoomTransitionFrameFitting: String {
    case zoomedInAspectFittingZoomedOut
    case zoomedOutAspectFittingZoomedIn
}

protocol ZoomTransitionDelegate: NSObjectProtocol {

    func zoomTransitionSnapshotReferenceView(_ transition: ZoomTransition) -> UIView

    func zoomTransitionFrameFitting(_ transition: ZoomTransition) -> ZoomTransitionFrameFitting?

    func zoomTransition(_ transition: ZoomTransition,
                        originForZoomedOutFrameZoomedIn frame: CGRect) -> CGPoint

    func zoomTransition(_ transition: ZoomTransition,
                        willCreateSnapshotViewFromReferenceView reference: UIView)

    func zoomTransition(_ transition: ZoomTransition,
                        didCreateSnapshotView snapshot: UIView,
                        fromReferenceView reference: UIView)

    func zoomTransitionWillTransition(_ transition: ZoomTransition)

    func zoomTransitionDidTransition(_ transition: ZoomTransition)

    func zoomTransition(_ transition: ZoomTransition,
                        subviewsToAnimateSeparatelyForReferenceView reference: UIView) -> [UIView]

    func zoomTransition(_ transition: ZoomTransition,
                        subviewInDestinationViewController viewController: UIViewController,
                        forSubview subview: UIView) -> UIView?

}

extension ZoomTransitionDelegate { /** For testing. */

    func zoomTransitionSnapshotReferenceView(_ transition: ZoomTransition) -> UIView {
        return UIView(frame: .zero)
    }

    func zoomTransitionFrameFitting(_ transition: ZoomTransition) -> ZoomTransitionFrameFitting? {
        return nil
    }

    func zoomTransition(_ transition: ZoomTransition,
                        originForZoomedOutFrameZoomedIn frame: CGRect) -> CGPoint {
        return frame.origin
    }

    func zoomTransition(_ transition: ZoomTransition,
                        willCreateSnapshotViewFromReferenceView reference: UIView) {}

    func zoomTransition(_ transition: ZoomTransition,
                        didCreateSnapshotView snapshot: UIView,
                        fromReferenceView reference: UIView) {}

    func zoomTransitionWillTransition(_ transition: ZoomTransition) {}

    func zoomTransitionDidTransition(_ transition: ZoomTransition) {}

    func zoomTransition(_ transition: ZoomTransition,
                        subviewsToAnimateSeparatelyForReferenceView reference: UIView) -> [UIView] {
        return []
    }

    func zoomTransition(_ transition: ZoomTransition,
                        subviewInDestinationViewController viewController: UIViewController,
                        forSubview subview: UIView) -> UIView? {
        return nil
    }
}

/**
 Note that because the image-backed snapshot views will scale their image according to their
 `frame`, only animating `frame` is enough and the expected `transform` animation isn't needed.
 Using frames is also simpler given we're animating from one reference view to another and don't
 need to calculate as many transforms.
 */
class ZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {

    fileprivate(set) weak var delegate: ZoomTransitionDelegate!

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

    fileprivate(set) weak var zoomedInView: UIView!
    fileprivate(set) weak var zoomedOutView: UIView!

    fileprivate(set) weak var zoomedInViewController: UIViewController!
    fileprivate(set) weak var zoomedOutViewController: UIViewController!

    fileprivate var frameFitting: ZoomTransitionFrameFitting {
        return delegate.zoomTransitionFrameFitting(self) ?? .zoomedInAspectFittingZoomedOut
    }

    fileprivate var zoomedInPlaceholder: UIView!
    fileprivate var zoomedOutPlaceholder: UIView!

    fileprivate var zoomedInCenter: CGPoint!
    fileprivate var zoomedOutCenter: CGPoint!

    fileprivate var zoomedInSubviews: [UIView]?
    fileprivate var zoomedOutSubviews: [UIView]?

    fileprivate var zoomedInSubviewSnapshots: [UIView]?
    fileprivate var zoomedOutSubviewSnapshots: [UIView]?

    fileprivate var usesSingleSubview: Bool {
        return zoomedOutSubviews?.count == 1 && zoomedInSubviews == nil
    }

    /** Scale of `zoomedOutFrame` based on `zoomedInFrame`. */
    fileprivate var aspectFittingScale: CGFloat {
        switch frameFitting {
        case .zoomedInAspectFittingZoomedOut:
            return min(
                (zoomedOutFrame.width - 2 * zoomedOutReferenceViewBorderWidth) / zoomedInFrame.width,
                (zoomedOutFrame.height - 2 * zoomedOutReferenceViewBorderWidth) / zoomedInFrame.height
            )
        case .zoomedOutAspectFittingZoomedIn:
            return max(
                (zoomedOutFrame.width - 2 * zoomedOutReferenceViewBorderWidth) / zoomedInFrame.width,
                (zoomedOutFrame.height - 2 * zoomedOutReferenceViewBorderWidth) / zoomedInFrame.height
            )
        }
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

    init(delegate: ZoomTransitionDelegate) {
        super.init()
        self.delegate = delegate
    }

    fileprivate func createSnapshotView(from referenceView: UIView) -> UIView {
        delegate.zoomTransition(self, willCreateSnapshotViewFromReferenceView: referenceView)
        let snapshot = referenceView.snapshotView(afterScreenUpdates: true)
        delegate.zoomTransition(self, didCreateSnapshotView: snapshot!, fromReferenceView: referenceView)
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

        zoomedOutView = delegate.zoomTransitionSnapshotReferenceView(self)

        zoomedOutSubviews = delegate.zoomTransition(
            self, subviewsToAnimateSeparatelyForReferenceView: zoomedOutView
        )

        if let sources = self.zoomedOutSubviews {
            var destinations: [UIView] = []
            sources.forEach {
                guard
                    let subview = self.delegate.zoomTransition(
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

    fileprivate func addTransitionSubviews() {
        let (_, _, containerView, _) = unpackTransitionContext()

        zoomedInSubviews?.forEach { $0.alpha = 0 }
        zoomedInPlaceholder = createSnapshotView(from: zoomedInView)
        zoomedInSubviews?.forEach { $0.alpha = 1 }

        zoomedOutPlaceholder = createSnapshotView(from: zoomedOutView)

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
            containerView.insertSubview(zoomedInPlaceholder, belowSubview: zoomedOutSnapshots.first!)
        } else {
            containerView.addSubview(zoomedInPlaceholder)
        }
        containerView.insertSubview(zoomedOutPlaceholder, belowSubview: zoomedInPlaceholder)
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
        addTransitionSubviews()
    }

    override fileprivate func start() {
        zoomedInView.frame = zoomedInFrame
        zoomedInCenter = zoomedInView.center

        zoomedOutPlaceholder.frame = zoomedOutFrame
        zoomedOutCenter = zoomedOutPlaceholder.center

        if let count = zoomedInSubviews?.count, count > 0 {
            zoomedInView.layoutIfNeeded()
        }

        zoomedInPlaceholder.alpha = 0
        zoomedInPlaceholder.frame = aspectFittingZoomedInFrameOfZoomedOutSize
        zoomedInPlaceholder.center = zoomedOutCenter

        delegate.zoomTransitionWillTransition(self)
    }

    override fileprivate func finish() {
        zoomedInPlaceholder.alpha = 1
        zoomedInPlaceholder.frame = zoomedInFrame

        let expandedFrame = aspectFittingZoomedOutFrameOfZoomedInSize
        zoomedOutPlaceholder.frame = expandedFrame
        zoomedOutPlaceholder.center = zoomedInCenter
        zoomedOutPlaceholder.frame.origin = delegate.zoomTransition(
            self, originForZoomedOutFrameZoomedIn: zoomedOutPlaceholder.frame
        )

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
        let (_, _, containerView, transitionContext) = unpackTransitionContext()

        if finished {
            containerView.subviews.forEach { $0.removeFromSuperview() }
            containerView.addSubview(zoomedInView)
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

        delegate.zoomTransitionDidTransition(self)
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
                    self.zoomedInPlaceholder.alpha = 0
                    self.zoomedOutPlaceholder.alpha = 1
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
        addTransitionSubviews()
    }

    override fileprivate func start() {
        zoomedInCenter = zoomedInView.center

        zoomedInPlaceholder.frame = zoomedInFrame

        zoomedOutPlaceholder.alpha = 0
        zoomedOutPlaceholder.frame = aspectFittingZoomedOutFrameOfZoomedInSize
        zoomedOutPlaceholder.center = zoomedInCenter
        zoomedOutPlaceholder.frame.origin = delegate.zoomTransition(
            self, originForZoomedOutFrameZoomedIn: zoomedOutPlaceholder.frame
        )

        if let destinations = zoomedInSubviewSnapshots, !destinations.isEmpty {
            for (index, destination) in destinations.enumerated() {
                guard let source = self.zoomedOutSubviewSnapshots?[index] else { continue }
                source.frame.origin = destination.frame.origin
            }

        } else if usesSingleSubview, let snapshotView = zoomedOutSubviewSnapshots?.first {
            snapshotView.removeFromSuperview()
        }

        zoomedInView.removeFromSuperview()

        delegate.zoomTransitionWillTransition(self)
    }

    override fileprivate func finish() {
        zoomedInPlaceholder.frame = aspectFittingZoomedInFrameOfZoomedOutSize
        zoomedOutPlaceholder.frame = zoomedOutFrame
        zoomedInPlaceholder.center = zoomedOutPlaceholder.center

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
        let (_, _, containerView, transitionContext) = unpackTransitionContext()

        if finished {
            containerView.subviews.forEach { $0.removeFromSuperview() }
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

        delegate.zoomTransitionDidTransition(self)
    }

}
