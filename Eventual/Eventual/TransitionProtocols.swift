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
                                     didTransitionWithSnapshotReferenceView reference: UIView,
                                     fromViewController: UIViewController, toViewController: UIViewController, reversed: Bool)

    optional func animatedTransition(transition: AnimatedTransition,
                                     subviewsToAnimateSeparatelyForReferenceView reference: UIView) -> [UIView]

    optional func animatedTransition(transition: AnimatedTransition,
                                     subviewInDestinationViewController viewController: UIViewController,
                                     forSubview subview: UIView) -> UIView?

}

@objc protocol AnimatedTransition: UIViewControllerAnimatedTransitioning {}
