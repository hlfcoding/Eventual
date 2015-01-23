//
//  ZoomTransitionController.swift
//  Eventual
//
//  Created by Peng Wang on 7/20/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import QuartzCore

@objc(ETAnimatedZoomTransition) class AnimatedZoomTransition: NSObject, AnimatedTransition {
    
    private weak var delegate: TransitionAnimationDelegate!

    var inFrame: CGRect?
    var inDelay: NSTimeInterval = 0.3
    
    var outDelay: NSTimeInterval = 0.0
    var outFrame = CGRectZero
    
    var completionCurve: UIViewAnimationCurve = .EaseInOut
    var duration: NSTimeInterval = 0.3
    
    var isReversed: Bool = false
    
    init(delegate: TransitionAnimationDelegate) {
        super.init()
        self.delegate = delegate
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView()
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        // Decide values.
        let shouldZoomOut = self.isReversed
        let inFrame = self.inFrame ?? transitionContext.finalFrameForViewController(shouldZoomOut ? toViewController : fromViewController)
        let outFrame = self.outFrame
        let finalFrame = shouldZoomOut ? outFrame : inFrame
        let initialFrame = shouldZoomOut ? inFrame : outFrame
        let finalAlpha: CGFloat = shouldZoomOut ? 0.0 : 1.0
        let initialAlpha: CGFloat = shouldZoomOut ? 1.0 : 0.0
        // Setup views.
        let presentedView = shouldZoomOut ? fromViewController.view : toViewController.view
        var snapshotReferenceView: UIView!
        var snapshotView: UIView!
        let setupOperation = NSBlockOperation {
            if shouldZoomOut {
                snapshotReferenceView = self.delegate.animatedTransition(self, snapshotReferenceViewWhenReversed: self.isReversed)
            } else {
                presentedView.frame = finalFrame
                snapshotReferenceView = presentedView
            }
            self.delegate.animatedTransition(self, willCreateSnapshotViewFromSnapshotReferenceView: snapshotReferenceView)
            snapshotView = snapshotReferenceView.snapshotViewAfterScreenUpdates(true)
            self.delegate.animatedTransition(self, didCreateSnapshotViewFromSnapshotReferenceView: snapshotReferenceView)
            snapshotView.frame = CGRect(
                x: initialFrame.origin.x,
                y: initialFrame.origin.y,
                width: initialFrame.size.width,
                height: initialFrame.size.width / finalFrame.size.width * finalFrame.size.height
            )
            snapshotView.alpha = initialAlpha
            containerView.addSubview(snapshotView)
            if shouldZoomOut {
                presentedView.removeFromSuperview()
            }
        }
        let operationQueue = NSOperationQueue.mainQueue()
        operationQueue.addOperation(setupOperation)
        // Animate views.
        let animateOperation = NSBlockOperation {
            let applyScalar: (CGFloat) -> Void = { scalar in
                snapshotView.layer.transform = CATransform3DMakeScale(1.0, 1.0, scalar)
                snapshotView.alpha = scalar
            }
            UIView.animateKeyframesWithDuration( self.duration,
                delay: shouldZoomOut ? self.outDelay : self.inDelay,
                options: .CalculationModeCubic,
                animations: {
                    UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.2, animations: { applyScalar(shouldZoomOut ? 0.8 : 0.2) } )
                    UIView.addKeyframeWithRelativeStartTime(0.2, relativeDuration: 0.6, animations: { applyScalar(shouldZoomOut ? 0.2 : 0.8) } )
                    UIView.addKeyframeWithRelativeStartTime(0.8, relativeDuration: 0.2, animations: { applyScalar(shouldZoomOut ? 0.0 : 1.0) } )
                    snapshotView.frame = finalFrame
                }, completion: { finished in
                    if finished && !shouldZoomOut {
                        containerView.addSubview(presentedView)
                        snapshotView.removeFromSuperview()
                    }
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                }
            )
        }
        animateOperation.addDependency(setupOperation)
        operationQueue.addOperation(animateOperation)
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return self.duration
    }
    
}

@objc(ETInteractiveZoomTransition) class InteractiveZoomTransition: UIPercentDrivenInteractiveTransition, InteractiveTransition, UIGestureRecognizerDelegate {

    private weak var delegate: TransitionInteractionDelegate?

    var minVelocityThreshold: CGFloat = 5.0
    var maxCompletionThreshold: CGFloat = 0.5
    var minScaleDeltaThreshold: CGFloat = 1.0

    var isReversed: Bool = false

    private var pinchRecognizer: UIPinchGestureRecognizer!
    private var pinchWindow: UIWindow!
    private var sourceScale: CGFloat?
    private var destinationScale: CGFloat?
    private var isTransitioning = false

    init(delegate: TransitionInteractionDelegate) {
        super.init()
        self.delegate = delegate
    }

    func setUp() {
        self.pinchRecognizer = UIPinchGestureRecognizer(target: self, action: Selector("handlePinch:"))
        self.pinchRecognizer.delegate = self
        if let delegate = self.delegate {
            self.pinchWindow = delegate.interactiveTransition(self, windowForGestureRecognizer: self.pinchRecognizer)
        }
        self.pinchWindow.addGestureRecognizer(self.pinchRecognizer)
    }

    func tearDown() {
        self.pinchWindow.removeGestureRecognizer(self.pinchRecognizer)
    }

    @IBAction private func handlePinch(pinchRecognizer: UIPinchGestureRecognizer) {
        var computedProgress: CGFloat?
        let scale = pinchRecognizer.scale
        let state = pinchRecognizer.state
        let velocity = pinchRecognizer.velocity
        func tearDown() {
            self.isTransitioning = false
            self.sourceScale = nil
            self.destinationScale = nil
        }
        println("DEBUG: state: \(state.rawValue), scale: \(scale), velocity: \(velocity)")
        switch state {
        case .Began:
            if self.delegate == nil { return }
            let delegate = self.delegate!
            let contextView = delegate.interactiveTransition(self, locationContextViewForGestureRecognizer: pinchRecognizer)
            let location = pinchRecognizer.locationInView(contextView)
            if let referenceView = delegate.interactiveTransition(self, snapshotReferenceViewAtLocation: location, ofContextView: contextView) {
                self.isTransitioning = true
                self.sourceScale = scale
                self.destinationScale = (
                    delegate.interactiveTransition?(self, destinationScaleForSnapshotReferenceView: referenceView, contextView: contextView)
                    ?? contextView.frame.size.width / referenceView.frame.size.width
                )
                println("DEBUG: reference: \(referenceView), destination: \(self.destinationScale)")
                delegate.beginInteractiveTransition(self, withSnapshotReferenceView: referenceView)
            }

        case .Changed:
            if self.destinationScale == nil { return }
            // TODO: Factor in velocity.
            let percentComplete = scale / self.destinationScale!
            println("DEBUG: percent: \(percentComplete)")
            self.updateInteractiveTransition(percentComplete)

        case .Ended:
            var isCancelled = fabs(velocity) < self.minVelocityThreshold && self.percentComplete < self.maxCompletionThreshold
            if !isCancelled && self.sourceScale != nil {
                let delta = fabs(scale - self.sourceScale!)
                isCancelled = delta < self.minScaleDeltaThreshold
                println("DEBUG: delta: \(delta)")
            }
            if isCancelled {
                self.cancelInteractiveTransition()
            } else {
                self.finishInteractiveTransition()
            }
            tearDown()

        case .Cancelled:
            self.cancelInteractiveTransition()
            tearDown()

        case .Failed:
            println("FAILED: percent: \(self.percentComplete)")
            tearDown()

        case .Possible:
            fatalError("This should never happen.")
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}