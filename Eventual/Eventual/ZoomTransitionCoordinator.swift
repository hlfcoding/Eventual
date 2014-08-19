//
//  ZoomTransitionCoordinator.swift
//  Eventual
//
//  Created by Peng Wang on 7/20/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit
import QuartzCore

@objc(ETZoomTransitionCoordinator) class ZoomTransitionCoordinator: NSObject {
    
    weak var zoomContainerView: UIView?
    weak var zoomedOutView: UIView?
    var zoomedOutFrame: CGRect!
    
    var zoomDuration: NSTimeInterval!
    var zoomCompletionCurve: UIViewAnimationCurve!
    var isZoomReversed: Bool!
    var isZoomInteractive: Bool! // TODO: Implement.
    
    private weak var dismissedViewController: UIViewController?
    private weak var presentedViewController: UIViewController?
    private weak var presentingViewController: UIViewController?
    private weak var sourceViewController: UIViewController?
    private weak var transitionContext: UIViewControllerContextTransitioning?
    
    private var isZoomCancelled = false
    
    override init() {
        super.init()
        self.setToInitialContext()
    }
    
    private func setToInitialContext() {
        self.zoomContainerView = nil
        self.zoomedOutView = nil
        self.zoomedOutFrame = CGRectZero
        
        self.zoomDuration = 0.3
        self.zoomCompletionCurve = .EaseInOut
        self.isZoomReversed = false
        self.isZoomInteractive = false
    }
    
    private func animate() {
        if self.transitionContext == nil { return }
        let containerView = self.transitionContext!.containerView()
        let sourceViewController = self.transitionContext!.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let presentedViewController = self.transitionContext!.viewControllerForKey(UITransitionContextToViewControllerKey)
        // Decide values.
        let shouldZoomOut = self.isZoomReversed
        let inFrame = self.transitionContext!.finalFrameForViewController(shouldZoomOut ? presentedViewController : sourceViewController)
        let outFrame = self.zoomedOutFrame
        let finalFrame = shouldZoomOut ? outFrame : inFrame
        let initialFrame = shouldZoomOut ? inFrame : outFrame
        let finalAlpha: CGFloat = shouldZoomOut ? 0.0 : 1.0
        let initialAlpha: CGFloat = shouldZoomOut ? 1.0 : 0.0
        // Setup views.
        let presentedView = shouldZoomOut ? sourceViewController.view : presentedViewController.view
        var snapshotReferenceView: UIView!
        var snapshotView: UIView!
        let setupOperation = NSBlockOperation {
            presentedView.frame = finalFrame
            snapshotReferenceView = shouldZoomOut ? self.zoomedOutView : presentedView
            if !shouldZoomOut {
                containerView.insertSubview(presentedView, atIndex: 0)
            }
            snapshotView = snapshotReferenceView.snapshotViewAfterScreenUpdates(true)
            snapshotView.frame = CGRect(
                x: initialFrame.origin.x, y: initialFrame.origin.y, width: initialFrame.size.width,
                height: initialFrame.size.width / finalFrame.size.height * finalFrame.size.height
            )
            snapshotView.alpha = initialAlpha
            if shouldZoomOut {
                presentedView.removeFromSuperview()
            }
        }
        let operationQueue = NSOperationQueue.mainQueue()
        operationQueue.addOperation(setupOperation)
        // Animate views.
        let animateOperation = NSBlockOperation {
            func applyScalar(scalar: CGFloat) {
                snapshotView.layer.transform = CATransform3DMakeScale(1.0, 1.0, scalar)
                snapshotView.alpha = scalar
            }
            UIView.animateKeyframesWithDuration( self.zoomDuration, delay: 0.0,
                options: .CalculationModeCubic,
                animations: {
                    UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.2, animations: { applyScalar(shouldZoomOut ? 0.8 : 0.2) } )
                    UIView.addKeyframeWithRelativeStartTime(0.2, relativeDuration: 0.6, animations: { applyScalar(shouldZoomOut ? 0.2 : 0.8) } )
                    UIView.addKeyframeWithRelativeStartTime(0.8, relativeDuration: 0.2, animations: { applyScalar(shouldZoomOut ? 0.0 : 1.0) } )
                    snapshotView.frame = finalFrame
                }, completion: { finished in
                    if !finished { return }
                    if !shouldZoomOut {
                        containerView.bringSubviewToFront(presentedView)
                        snapshotView.removeFromSuperview()
                    }
                    self.transitionContext!.completeTransition(true)
                }
            )
        }
        animateOperation.addDependency(setupOperation)
        operationQueue.addOperation(animateOperation)
    }
}

extension ZoomTransitionCoordinator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning!) -> NSTimeInterval {
        return self.zoomDuration
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning!) {
        self.transitionContext = transitionContext
        self.animate()
    }
    
    func animationEnded(transitionCompleted: Bool) {
        self.setToInitialContext()
    }
    
}

extension ZoomTransitionCoordinator: UIViewControllerInteractiveTransitioning {

    func startInteractiveTransition(transitionContext: UIViewControllerContextTransitioning!) {
        self.transitionContext = transitionContext
    }
    
}

extension ZoomTransitionCoordinator: UIViewControllerTransitionCoordinatorContext {
    
    func isAnimated() -> Bool {
        return true
    }
    
    func presentationStyle() -> UIModalPresentationStyle {
        return .Custom
    }
    
    func initiallyInteractive() -> Bool {
        return self.isZoomInteractive
    }
    
    func isInteractive() -> Bool {
        return self.isZoomInteractive
    }
    
    func isCancelled() -> Bool {
        return self.isZoomCancelled
    }
    
    func transitionDuration() -> NSTimeInterval {
        return self.zoomDuration
    }
    
    func percentComplete() -> CGFloat {
        return 0.0
    }
    func completionVelocity() -> CGFloat {
        return 0.0
    }
    func completionCurve() -> UIViewAnimationCurve {
        return self.zoomCompletionCurve
    }
    
    func viewControllerForKey(key: String!) -> UIViewController! {
        switch key! {
        case UITransitionContextFromViewControllerKey:
            return self.sourceViewController
        case UITransitionContextToViewControllerKey:
            return self.presentedViewController
        default:
            return nil
        }
    }
    
    func containerView() -> UIView! {
        return self.containerView()
    }

    // TODO: New.
    
    func viewForKey(key: String!) -> UIView! {
        return nil
    }

    func targetTransform() -> CGAffineTransform {
        return CGAffineTransformIdentity
    }
    
    func isRotating() -> Bool {
        return false
    }
}

extension ZoomTransitionCoordinator: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController!, presentingController presenting: UIViewController!,
         sourceController source: UIViewController!) -> UIViewControllerAnimatedTransitioning!
    {
        self.presentedViewController = presented
        self.presentingViewController = presenting
        self.sourceViewController = source
        return self
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController!) -> UIViewControllerAnimatedTransitioning! {
        self.dismissedViewController = dismissed
        return self
    }
    
    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning!) -> UIViewControllerInteractiveTransitioning! {
        return self.isZoomInteractive ? self : nil
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning!) -> UIViewControllerInteractiveTransitioning! {
        return self.isZoomInteractive ? self : nil
    }
    
}

extension ZoomTransitionCoordinator: UIViewControllerTransitionCoordinator {

    func animateAlongsideTransition(animation: ((UIViewControllerTransitionCoordinatorContext!) -> Void)!,
         completion: ((UIViewControllerTransitionCoordinatorContext!) -> Void)!) -> Bool
    {
        return true
    }
    
    func animateAlongsideTransitionInView(view: UIView!, animation: ((UIViewControllerTransitionCoordinatorContext!) -> Void)!,
         completion: ((UIViewControllerTransitionCoordinatorContext!) -> Void)!) -> Bool
    {
        return true
    }
    
    func notifyWhenInteractionEndsUsingBlock(handler: ((UIViewControllerTransitionCoordinatorContext!) -> Void)!) {}

}