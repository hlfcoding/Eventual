//
//  CollectionViewZoomTransitionTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@objc protocol CollectionViewZoomTransitionTraitDelegate: NSObjectProtocol {

    var collectionView: UICollectionView? { get }
    var currentIndexPath: NSIndexPath? { get set }

    func animatedTransition(transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView]

    optional func animatedTransition(transition: AnimatedTransition,
                                     subviewInDestinationViewController viewController: UIViewController,
                                     forSubview subview: UIView) -> UIView?

}

class CollectionViewZoomTransitionTrait: NSObject,
UIViewControllerTransitioningDelegate, TransitionAnimationDelegate {

    private(set) weak var delegate: CollectionViewZoomTransitionTraitDelegate!

    private var collectionView: UICollectionView! { return delegate.collectionView! }

    init(delegate: CollectionViewZoomTransitionTraitDelegate) {
        super.init()
        self.delegate = delegate
    }

    // MARK: - UIViewControllerTransitioningDelegate

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController,
                                                   sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = ZoomInTransition(delegate: self)
        transition.zoomedOutReferenceViewBorderWidth = CollectionViewTileCell.borderSize

        let cell = animatedTransition(transition, snapshotReferenceViewWhenReversed: false)
        transition.zoomedOutFrame = cell.frame

        let offset = collectionView.contentOffset
        transition.zoomedOutFrame.offsetInPlace(dx: -offset.x, dy: -offset.y)
        return transition
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let source = presentingViewControllerForViewController(dismissed) as? UICollectionViewController
            else { preconditionFailure() }

        let transition = ZoomOutTransition(delegate: self)
        transition.zoomedOutReferenceViewBorderWidth = CollectionViewTileCell.borderSize

        if dismissed is CollectionViewBackgroundTapTraitDelegate {
            transition.transitionDelay = CollectionViewBackgroundTapDuration + 0.1
        }

        let cell = animatedTransition(transition, snapshotReferenceViewWhenReversed: true)
        transition.zoomedOutFrame = cell.frame

        let borderSize = CollectionViewTileCell.borderSize
        transition.zoomedOutFrame.insetInPlace(dx: -borderSize, dy: -borderSize)

        let offset = source.collectionView!.contentOffset
        transition.zoomedOutFrame.offsetInPlace(dx: -offset.x, dy: -offset.y)
        return transition
    }

    // MARK: - TransitionAnimationDelegate

    func animatedTransition(transition: AnimatedTransition,
                            snapshotReferenceViewWhenReversed reversed: Bool) -> UIView {
        guard let indexPath = delegate.currentIndexPath else { return collectionView }
        return collectionView.cellForItemAtIndexPath(indexPath) ??
            collectionView.dataSource!.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    }

    func animatedTransition(transition: AnimatedTransition,
                            willCreateSnapshotViewFromReferenceView reference: UIView) {
        guard let cell = reference as? CollectionViewTileCell else { return }
        switch transition {
        case is ZoomInTransition:
            cell.staticContentSubviews.forEach { $0.hidden = true }
        case is ZoomOutTransition:
            if animatedTransition(transition, subviewsToAnimateSeparatelyForReferenceView: reference).count > 1 {
                cell.staticContentSubviews.forEach { $0.hidden = true }
            }
        default: break
        }
    }

    func animatedTransition(transition: AnimatedTransition,
                            didCreateSnapshotView snapshot: UIView, fromReferenceView reference: UIView) {
        guard let cell = reference as? CollectionViewTileCell else { return }
        cell.staticContentSubviews.forEach { $0.hidden = false }
    }

    func animatedTransition(transition: AnimatedTransition,
                            willTransitionWithSnapshotReferenceView reference: UIView, reversed: Bool) {
        guard let _ = transition as? ZoomTransition else { preconditionFailure() }
        if let cell = reference as? CollectionViewTileCell {
            cell.alpha = 0
        }
    }

    func animatedTransition(transition: AnimatedTransition,
                            didTransitionWithSnapshotReferenceView reference: UIView,
                            fromViewController: UIViewController, toViewController: UIViewController, reversed: Bool) {
        guard let _ = transition as? ZoomTransition else { preconditionFailure() }
        if let cell = reference as? CollectionViewTileCell {
            cell.alpha = 1
        }
    }

    func animatedTransition(transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceView reference: UIView) -> [UIView] {
        guard let cell = reference as? CollectionViewTileCell where transition is ZoomTransition else { return [] }
        return delegate.animatedTransition(transition, subviewsToAnimateSeparatelyForReferenceCell: cell)
    }

    func animatedTransition(transition: AnimatedTransition,
                            subviewInDestinationViewController viewController: UIViewController,
                            forSubview subview: UIView) -> UIView? {
        var actualViewController = viewController
        if let navigationController = viewController as? UINavigationController {
            actualViewController = navigationController.topViewController!
        }
        return delegate.animatedTransition?(
            transition, subviewInDestinationViewController: actualViewController, forSubview: subview
        )
    }

    // MARK: - Helpers

    private func presentingViewControllerForViewController(viewController: UIViewController) -> UIViewController? {
        var presenting = viewController.presentingViewController
        if let navigationController = presenting as? UINavigationController {
            presenting = navigationController.topViewController
        }
        return presenting
    }

}
