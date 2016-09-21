//
//  TransitionProtocols.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@objc protocol TransitionAnimationDelegate: NSObjectProtocol {

    func animatedTransition(_ transition: AnimatedTransition,
                            snapshotReferenceViewWhenReversed reversed: Bool) -> UIView

    @objc optional func animatedTransition(_ transition: AnimatedTransition,
                                           willCreateSnapshotViewFromReferenceView reference: UIView)

    @objc optional func animatedTransition(_ transition: AnimatedTransition,
                                           didCreateSnapshotView snapshot: UIView,
                                           fromReferenceView reference: UIView)

    @objc optional func animatedTransition(_ transition: AnimatedTransition,
                                           willTransitionWithSnapshotReferenceView reference: UIView, reversed: Bool)

    @objc optional func animatedTransition(_ transition: AnimatedTransition,
                                           didTransitionWithSnapshotReferenceView reference: UIView,
                                           fromViewController: UIViewController, toViewController: UIViewController, reversed: Bool)

    @objc optional func animatedTransition(_ transition: AnimatedTransition,
                                           subviewsToAnimateSeparatelyForReferenceView reference: UIView) -> [UIView]

    @objc optional func animatedTransition(_ transition: AnimatedTransition,
                                           subviewInDestinationViewController viewController: UIViewController,
                                           forSubview subview: UIView) -> UIView?

}

@objc protocol AnimatedTransition: UIViewControllerAnimatedTransitioning {}
