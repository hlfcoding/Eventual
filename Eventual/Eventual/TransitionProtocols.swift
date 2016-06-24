//
//  TransitionProtocols.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@objc protocol TransitionAnimationDelegate: NSObjectProtocol {

    func animatedTransition(transition: AnimatedTransition,
                            snapshotReferenceViewWhenReversed reversed: Bool) -> UIView

    optional func animatedTransition(transition: AnimatedTransition,
                                     willCreateSnapshotViewFromReferenceView reference: UIView)

    optional func animatedTransition(transition: AnimatedTransition,
                                     didCreateSnapshotView snapshot: UIView,
                                     fromReferenceView reference: UIView)

    optional func animatedTransition(transition: AnimatedTransition,
                                     willTransitionWithSnapshotReferenceView reference: UIView, reversed: Bool)

    optional func animatedTransition(transition: AnimatedTransition,
                                     didTransitionWithSnapshotReferenceView reference: UIView, reversed: Bool)

    optional func animatedTransition(transition: AnimatedTransition,
                                     subviewsToAnimateSeparatelyForReferenceView reference: UIView) -> [UIView]

    optional func animatedTransition(transition: AnimatedTransition,
                                     subviewInDestinationViewController viewController: UIViewController,
                                     forSubview subview: UIView) -> UIView?

}

protocol TransitionInteractionDelegate: NSObjectProtocol {

    func interactiveTransition(transition: InteractiveTransition,
                               locationContextViewForGestureRecognizer recognizer: UIGestureRecognizer) -> UIView

    func interactiveTransition(transition: InteractiveTransition,
                               snapshotReferenceViewAtLocation location: CGPoint,
                               ofContextView contextView: UIView) -> UIView?

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
                                                withSnapshotReferenceView referenceView: UIView?)

    func beginInteractiveDismissalTransition(transition: InteractiveTransition,
                                             withSnapshotReferenceView referenceView: UIView?)

    func interactiveTransition(transition: InteractiveTransition,
                               destinationScaleForSnapshotReferenceView referenceView: UIView?,
                               contextView: UIView, reversed: Bool) -> CGFloat

}

@objc protocol AnimatedTransition: UIViewControllerAnimatedTransitioning {}

@objc protocol InteractiveTransition: UIViewControllerInteractiveTransitioning {

    var isEnabled: Bool { get set }

}
