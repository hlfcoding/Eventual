//
//  ZoomTransitionController.swift
//  Eventual
//
//  Created by Peng Wang on 7/20/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import QuartzCore

class AnimatedZoomTransition: NSObject, AnimatedTransition {
    
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
        if let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
               toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
               containerView = transitionContext.containerView()
        {
            // Decide values.
            let shouldZoomOut = self.isReversed
            let inFrame = self.inFrame ?? transitionContext.finalFrameForViewController(shouldZoomOut ? toViewController : fromViewController)
            let outFrame = self.outFrame
            let finalFrame = shouldZoomOut ? outFrame : inFrame
            let initialFrame = shouldZoomOut ? inFrame : outFrame
            let finalAlpha: CGFloat = shouldZoomOut ? 0.0 : 1.0
            let initialAlpha: CGFloat = shouldZoomOut ? 1.0 : 0.0
            let finalScale: CGFloat = shouldZoomOut ? 0.01 : 1.0
            let initialScale: CGFloat = shouldZoomOut ? 1.0 : 0.01
            // Setup views.
            let presentedView = shouldZoomOut ? fromViewController.view : toViewController.view
            var snapshotReferenceView: UIView = presentedView
            if shouldZoomOut {
                snapshotReferenceView = self.delegate.animatedTransition(self, snapshotReferenceViewWhenReversed: self.isReversed)
            } else {
                presentedView.frame = finalFrame
            }
            self.delegate.animatedTransition(self, willCreateSnapshotViewFromSnapshotReferenceView: snapshotReferenceView)
            let snapshotView = snapshotReferenceView.snapshotViewAfterScreenUpdates(true)
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
            // Animate views.
            snapshotView.layer.transform = CATransform3DMakeScale(1.0, 1.0, initialScale)
            UIView.animateWithDuration( self.duration,
                delay: shouldZoomOut ? self.outDelay : self.inDelay,
                options: .CurveEaseInOut,
                animations: {
                    snapshotView.alpha = finalAlpha
                    snapshotView.frame = finalFrame
                    snapshotView.layer.transform = CATransform3DMakeScale(1.0, 1.0, finalScale)
                }, completion: { finished in
                    if finished && !shouldZoomOut {
                        containerView.addSubview(presentedView)
                        snapshotView.removeFromSuperview()
                    }
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                }
            )
        }
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return self.duration
    }
    
}

class InteractiveZoomTransition: UIPercentDrivenInteractiveTransition, InteractiveTransition, UIGestureRecognizerDelegate {

    private weak var delegate: TransitionInteractionDelegate?
    private weak var reverseDelegate: TransitionInteractionDelegate?

    var minVelocityThreshold =   (zoomIn: CGFloat(0.5), zoomOut: CGFloat(0.1))
    var maxCompletionThreshold = (zoomIn: CGFloat(0.5), zoomOut: CGFloat(0.3))
    var minScaleDeltaThreshold = (zoomIn: CGFloat(1.0), zoomOut: CGFloat(0.2))
    var minOutDestinationSpanThreshold: CGFloat = 10.0

    var isReversed: Bool = false

    private var pinchRecognizer: UIPinchGestureRecognizer! {
        didSet {
            self.pinchRecognizer.delegate = self
        }
    }
    private var pinchWindow: UIWindow!
    var pinchSpan: CGFloat {
        let firstLocation = self.pinchRecognizer.locationOfTouch(0, inView: self.pinchWindow)
        let secondLocation = self.pinchRecognizer.locationOfTouch(1, inView: self.pinchWindow)
        let xSpan = fabs(firstLocation.x - secondLocation.x)
        let ySpan = fabs(firstLocation.y - secondLocation.y)
        return fmax(xSpan, ySpan)
    }
    private var sourceScale: CGFloat?
    private var destinationScale: CGFloat?
    private var isTransitioning = false

    var isEnabled: Bool = false {
        didSet {
            if self.isEnabled {
                self.pinchWindow.addGestureRecognizer(self.pinchRecognizer)
            } else {
                self.pinchWindow.removeGestureRecognizer(self.pinchRecognizer)
            }
        }
    }

    init(delegate: TransitionInteractionDelegate,
         reverseDelegate: TransitionInteractionDelegate? = nil)
    {
        super.init()
        self.delegate = delegate
        self.reverseDelegate = reverseDelegate
        self.pinchRecognizer = UIPinchGestureRecognizer(target: self, action: Selector("handlePinch:"))
        self.pinchWindow = delegate.interactiveTransition(self, windowForGestureRecognizer: self.pinchRecognizer)
    }

    @IBAction private func handlePinch(sender: UIPinchGestureRecognizer) {
        var computedProgress: CGFloat?
        let scale = sender.scale
        let state = sender.state
        let velocity = sender.velocity
        func tearDown() {
            self.isReversed = false
            self.isTransitioning = false
            self.sourceScale = nil
            self.destinationScale = nil
        }
        print("DEBUG: state: \(state.rawValue), scale: \(scale), velocity: \(velocity)")
        switch state {
        case .Began:
            let isReversed = velocity < 0
            if self.testAndBeginInTransitionForScale(scale) ||
               (isReversed && self.testAndBeginOutTransitionForScale(scale))
            {
                self.isReversed = isReversed
                self.isTransitioning = true
                self.sourceScale = scale
            }

        case .Changed:
            if let destinationScale = self.destinationScale {
                // TODO: Factor in velocity.
                var percentComplete = scale / destinationScale
                if self.isReversed {
                    percentComplete = destinationScale / scale
                }
                percentComplete = fmax(0.0, fmin(1.0, percentComplete))
                print("DEBUG: percent: \(percentComplete)")
                self.updateInteractiveTransition(percentComplete)
            }

        case .Ended:
            var isCancelled = (fabs(velocity) < self.minVelocityThreshold.zoomIn &&
                               self.percentComplete < self.maxCompletionThreshold.zoomIn)
            if self.isReversed {
                isCancelled = (fabs(velocity) < self.minVelocityThreshold.zoomOut &&
                               self.percentComplete < self.maxCompletionThreshold.zoomOut)
            }
            if !isCancelled, let sourceScale = self.sourceScale {
                let delta = fabs(scale - sourceScale)
                isCancelled = delta < self.minScaleDeltaThreshold.zoomIn
                if self.isReversed {
                    isCancelled = delta < self.minScaleDeltaThreshold.zoomOut
                }
                print("DEBUG: delta: \(delta)")
            }
            if isCancelled {
                print("CANCELLED")
                self.cancelInteractiveTransition()
            } else {
                self.finishInteractiveTransition()
            }
            tearDown()

        case .Cancelled:
            self.cancelInteractiveTransition()
            tearDown()

        case .Failed:
            print("FAILED: percent: \(self.percentComplete)")
            tearDown()

        case .Possible:
            fatalError("This should never happen.")
        }
    }

    private func testAndBeginInTransitionForScale(scale: CGFloat) -> Bool {
        if let delegate = self.delegate {
            let contextView = delegate.interactiveTransition(self, locationContextViewForGestureRecognizer: pinchRecognizer)
            let location = pinchRecognizer.locationInView(contextView)
            if let referenceView = delegate.interactiveTransition(self, snapshotReferenceViewAtLocation: location, ofContextView: contextView) {
                self.destinationScale = delegate.interactiveTransition( self,
                    destinationScaleForSnapshotReferenceView: referenceView,
                    contextView: contextView, reversed: false
                )
                if self.destinationScale < 0 || self.destinationScale == nil {
                    self.destinationScale = contextView.frame.size.width / referenceView.frame.size.width
                }
                let destinationAmp = referenceView.frame.size.width / self.pinchSpan
                if let destinationScale = self.destinationScale {
                    self.destinationScale = destinationScale * destinationAmp
                    print("DEBUG: reference: \(referenceView), destination: \(destinationScale)")
                    delegate.beginInteractivePresentationTransition(self, withSnapshotReferenceView: referenceView)
                    return true
                }
            }
        }
        return false
    }

    private func testAndBeginOutTransitionForScale(scale: CGFloat) -> Bool {
        if let delegate = self.delegate
               where delegate.respondsToSelector(Selector("beginInteractiveDismissalTransition:withSnapshotReferenceView:")),
           let reverseDelegate = self.reverseDelegate
        {
            let contextView = delegate.interactiveTransition(self, locationContextViewForGestureRecognizer: pinchRecognizer)
            if delegate is UIViewController {
                self.destinationScale = reverseDelegate.interactiveTransition( self,
                    destinationScaleForSnapshotReferenceView: nil,
                    contextView: contextView, reversed: true
                )
            }
            if self.destinationScale == nil || self.destinationScale < 0 {
                self.destinationScale = self.minOutDestinationSpanThreshold / (self.pinchSpan * (1 / scale))
            }
            print("DEBUG: destination: \(self.destinationScale)")
            delegate.beginInteractiveDismissalTransition(self, withSnapshotReferenceView:nil)
            return true
        }
        return false
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UIPinchGestureRecognizer &&
           otherGestureRecognizer.view is UIWindow
        {
            return true
        }
        return false
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let recognizers = gestureRecognizer.view?.gestureRecognizers as NSArray?
               where recognizers.containsObject(otherGestureRecognizer)
        {
            let parentRecognizer = gestureRecognizer
            return recognizers.indexOfObject(parentRecognizer) < recognizers.indexOfObject(otherGestureRecognizer)
        }
        return false
    }

}