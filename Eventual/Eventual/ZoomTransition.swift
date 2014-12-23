//
//  ZoomTransitionController.swift
//  Eventual
//
//  Created by Peng Wang on 7/20/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import QuartzCore

@objc(ETAnimatedZoomTransition) class AnimatedZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    weak var delegate: TransitionAnimationDelegate!
    
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
                snapshotReferenceView = self.delegate.transitionSnapshotReferenceView(self.isReversed)
            } else {
                presentedView.frame = finalFrame
                snapshotReferenceView = presentedView
            }
            self.delegate.transitionWillCreateSnapshotViewFromSnapshotReferenceView(snapshotReferenceView)
            snapshotView = snapshotReferenceView.snapshotViewAfterScreenUpdates(true)
            self.delegate.transitionDidCreateSnapshotViewFromSnapshotReferenceView(snapshotReferenceView)
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
                    if !finished { return }
                    if !shouldZoomOut {
                        containerView.addSubview(presentedView)
                        snapshotView.removeFromSuperview()
                    }
                    transitionContext.completeTransition(true)
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