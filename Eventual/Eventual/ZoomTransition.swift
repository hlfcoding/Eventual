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
    /**
     This is a zero-rect by default, but setting to the frame of the source view controller's
     triggering view, for example a cell view, is suggested.
     */
    var zoomedOutFrame = CGRectZero

    var zoomedOutReferenceViewBorderWidth: CGFloat = 1.0

    private weak var transitionContext: UIViewControllerContextTransitioning?

    private weak var zoomedInView: UIView!
    private weak var zoomedOutView: UIView!

    private var zoomedInSnapshot: UIView!
    private var zoomedOutSnapshot: UIView!

    private var zoomedInCenter: CGPoint!
    private var zoomedOutCenter: CGPoint!

    private var zoomedInSubviews: [UIView]?
    private var zoomedOutSubviews: [UIView]?

    private var zoomedInSubviewSnapshots: [UIView]?
    private var zoomedOutSubviewSnapshots: [UIView]?

    private var aspectFittingScale: CGFloat {
        return min(
            self.zoomedOutFrame.width / self.zoomedInFrame.width,
            self.zoomedOutFrame.height / self.zoomedInFrame.height
        )
    }
    /** Does an aspect-fit expand based on `zoomedInFrame`. Does not perform centering. */
    private var aspectFittingZoomedOutFrameOfZoomedInSize: CGRect {
        var frame = CGRectApplyAffineTransform(self.zoomedInFrame, CGAffineTransformMakeScale(
            (self.zoomedOutFrame.width / self.aspectFittingScale) / self.zoomedInFrame.width,
            (self.zoomedOutFrame.height / self.aspectFittingScale) / self.zoomedInFrame.height
        ))
        // Account for borders.
        let outset = -self.zoomedOutReferenceViewBorderWidth
        frame.insetInPlace(dx: outset, dy: outset)
        return frame
    }

    /** Does an aspect-fit shrink based on `zoomedOutFrame`. Does not perform centering. */
    private var aspectFittingZoomedInFrameOfZoomedOutSize: CGRect {
        return CGRectApplyAffineTransform(self.zoomedOutFrame, CGAffineTransformMakeScale(
            (self.zoomedInFrame.width * self.aspectFittingScale) / self.zoomedOutFrame.width,
            (self.zoomedInFrame.height * self.aspectFittingScale) / self.zoomedOutFrame.height
        ))
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

    private func unpackTransitionContext() ->
                 (UIViewController, UIViewController, UIView, UIViewControllerContextTransitioning)
    {
        guard let transitionContext = self.transitionContext,
                  fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
                  toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
                  containerView = transitionContext.containerView()
              else { fatalError("Missing transitionContext or its values.") }

        return (fromViewController, toViewController, containerView, transitionContext)
    }

    // MARK: UIViewControllerAnimatedTransitioning

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext

        self.setUp()
        self.addSnapshots()
        self.start()
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }

    // MARK: Animation Steps

    private func setUp() {
        fatalError("Unimplemented method.")
    }

    private func addSnapshots() {
        fatalError("Unimplemented method.")
    }

    private func start() {
        fatalError("Unimplemented method.")
    }

    private func finish() {
        fatalError("Unimplemented method.")
    }

    private func tearDown(finished: Bool) {
        fatalError("Unimplemented method.")
    }
}

class ZoomInTransition: ZoomTransition {

    private var usesSingleSubview: Bool {
        return self.zoomedOutSubviews?.count == 1 && self.zoomedInSubviews == nil
    }

    override init(delegate: TransitionAnimationDelegate) {
        super.init(delegate: delegate)
        self.transitionDelay = 0.3
    }

    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(transitionContext)

        if self.usesSingleSubview,
            let snapshotView = self.zoomedOutSubviewSnapshots?.first
        {
            UIView.animateWithDuration( 0.5 * self.transitionDuration(transitionContext),
                delay: self.transitionDelay,
                options: [.CurveLinear],
                animations: { snapshotView.alpha = 0.0 },
                completion: nil
            )
        }

        UIView.animateWithDuration( self.transitionDuration(transitionContext),
            delay: self.transitionDelay,
            options: [.CurveEaseInOut],
            animations: { self.finish() },
            completion: { self.tearDown($0) }
        )
    }

    override private func setUp() {
        let (fromViewController, toViewController, _, transitionContext) = self.unpackTransitionContext()

        self.zoomedInView = toViewController.view
        if self.zoomedInFrame == CGRectZero {
            self.zoomedInFrame = transitionContext.finalFrameForViewController(fromViewController)
        }

        self.zoomedOutView = self.delegate.animatedTransition( self,
            snapshotReferenceViewWhenReversed: false)

        self.zoomedOutSubviews = self.delegate.animatedTransition?( self,
            subviewsToAnimateSeparatelyForReferenceView: self.zoomedOutView)

        if let sources = self.zoomedOutSubviews {
            var destinations = [UIView]()
            sources.forEach {
                guard let subview = self.delegate.animatedTransition?( self,
                      subviewInDestinationViewController: toViewController, forSubview: $0)
                      else { return }
                destinations.append(subview)
            }
            if !destinations.isEmpty {
                self.zoomedInSubviews = destinations
            }
        }
    }

    override private func addSnapshots() {
        let (_, _, containerView, _) = self.unpackTransitionContext()

        self.zoomedInSubviews?.forEach { $0.alpha = 0.0 }
        self.zoomedInSnapshot = self.createSnapshotViewFromReferenceView(self.zoomedInView)
        self.zoomedInSubviews?.forEach { $0.alpha = 1.0 }

        self.zoomedOutSnapshot = self.createSnapshotViewFromReferenceView(self.zoomedOutView)

        self.zoomedInSubviewSnapshots = self.zoomedInSubviews?.map {
            let snapshot = self.createSnapshotViewFromReferenceSubview($0, ofViewWithFrame: self.zoomedInFrame)
            if let subview = $0.subviews.first as? UITextView {
                snapshot.frame.offsetInPlace(
                    dx: subview.textContainer.lineFragmentPadding, // Guessing.
                    dy: subview.layoutMargins.top + subview.contentInset.top  // Guessing.
                )
            }
            return snapshot
        }

        self.zoomedOutSubviewSnapshots = self.zoomedOutSubviews?.map {
            return self.createSnapshotViewFromReferenceSubview($0, ofViewWithFrame: self.zoomedOutFrame)
        }

        containerView.addSubview(self.zoomedOutSnapshot)
        containerView.addSubview(self.zoomedInSnapshot)
        self.zoomedOutSubviewSnapshots?.forEach { containerView.addSubview($0) }
    }

    override private func start() {
        self.zoomedInView.frame = self.zoomedInFrame
        self.zoomedInCenter = self.zoomedInView.center

        self.zoomedOutSnapshot.frame = self.zoomedOutFrame
        self.zoomedOutCenter = self.zoomedOutSnapshot.center

        if self.zoomedInSubviews?.count > 0 {
            self.zoomedInView.layoutIfNeeded()
        }

        self.zoomedInSnapshot.alpha = 0.0
        self.zoomedInSnapshot.frame = self.aspectFittingZoomedInFrameOfZoomedOutSize
        self.zoomedInSnapshot.center = self.zoomedOutCenter

        self.delegate.animatedTransition?( self,
            willTransitionWithSnapshotReferenceView: self.zoomedOutView, reversed: false)
    }

    override private func finish() {
        self.zoomedInSnapshot.alpha = 1.0
        self.zoomedInSnapshot.frame = self.zoomedInFrame

        let expandedFrame = self.aspectFittingZoomedOutFrameOfZoomedInSize
        self.zoomedOutSnapshot.frame = expandedFrame
        self.zoomedOutSnapshot.center = self.zoomedInCenter

        if self.zoomedInSubviewSnapshots?.count > 0,
           let destinations = self.zoomedInSubviewSnapshots
        {
            for (index, destination) in destinations.enumerate() {
                guard let source = self.zoomedOutSubviewSnapshots?[index] else { continue }
                source.frame.origin = destination.frame.origin
            }

        } else if self.usesSingleSubview,
                  let snapshotView = self.zoomedOutSubviewSnapshots?.first
        {
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

        self.delegate.animatedTransition?( self,
            didTransitionWithSnapshotReferenceView: self.zoomedOutView, reversed: false)
    }

}

class ZoomOutTransition: ZoomTransition {

    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(transitionContext)

        UIView.animateWithDuration( self.transitionDuration(transitionContext) * 0.6,
            delay: self.transitionDelay,
            options: [.CurveEaseInOut],
            animations: { self.zoomedOutSnapshot.alpha = 1.0 },
            completion: nil
        )
        UIView.animateWithDuration( self.transitionDuration(transitionContext),
            delay: self.transitionDelay,
            options: [.CurveEaseInOut],
            animations: { self.finish() },
            completion: { self.tearDown($0) }
        )
    }

    private override func setUp() {
        let (fromViewController, toViewController, _, transitionContext) = self.unpackTransitionContext()

        self.zoomedInView = fromViewController.view
        self.zoomedInCenter = self.zoomedInView.center
        if self.zoomedInFrame == CGRectZero {
            self.zoomedInFrame = transitionContext.finalFrameForViewController(toViewController)
        }

        self.zoomedOutView = self.delegate.animatedTransition(self,
            snapshotReferenceViewWhenReversed: true)
    }

    private override func addSnapshots() {
        let (_, _, containerView, _) = self.unpackTransitionContext()

        self.zoomedInSnapshot = self.createSnapshotViewFromReferenceView(self.zoomedInView)
        self.zoomedOutSnapshot = self.createSnapshotViewFromReferenceView(self.zoomedOutView)

        containerView.addSubview(self.zoomedInSnapshot)
        containerView.addSubview(self.zoomedOutSnapshot)
    }

    private override func start() {
        self.zoomedInView.removeFromSuperview()

        self.zoomedInSnapshot.frame = self.zoomedInFrame

        self.zoomedOutSnapshot.alpha = 0.0
        self.zoomedOutSnapshot.frame = self.aspectFittingZoomedOutFrameOfZoomedInSize
        self.zoomedOutSnapshot.center = self.zoomedInCenter

        self.delegate.animatedTransition?( self,
            willTransitionWithSnapshotReferenceView: self.zoomedOutView, reversed: true)
    }

    private override func finish() {
        self.zoomedInSnapshot.frame = self.aspectFittingZoomedInFrameOfZoomedOutSize
        self.zoomedOutSnapshot.frame = self.zoomedOutFrame
        self.zoomedInSnapshot.center = self.zoomedOutSnapshot.center
    }

    private override func tearDown(finished: Bool) {
        let (_, _, containerView, transitionContext) = self.unpackTransitionContext()

        if finished {
            containerView.subviews.forEach { $0.removeFromSuperview() }
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())

        self.delegate.animatedTransition?( self,
            didTransitionWithSnapshotReferenceView: self.zoomedOutView, reversed: true)
    }

}
