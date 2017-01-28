//
//  CollectionViewZoomTransitionTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@objc protocol CollectionViewZoomTransitionTraitDelegate: NSObjectProtocol {

    var collectionView: UICollectionView? { get }
    var currentIndexPath: IndexPath? { get set }

    @objc optional func animatedTransition(_ transition: AnimatedTransition,
                                           subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView]

    @objc optional func animatedTransition(_ transition: AnimatedTransition,
                                           subviewInDestinationViewController viewController: UIViewController,
                                           forSubview subview: UIView) -> UIView?

    @objc optional func animatedTransition(_ transition: AnimatedTransition,
                                           snapshotReferenceViewForCell cell: UICollectionViewCell) -> UIView

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

    func animationController(forPresented presented: UIViewController, presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = ZoomInTransition(delegate: self)
        transition.zoomedOutReferenceViewBorderWidth = CollectionViewTileCell.borderSize
        let reference = animatedTransition(transition, snapshotReferenceViewWhenReversed: false)
        transition.zoomedOutFrame = reference.convert(reference.frame, to: nil)
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = ZoomOutTransition(delegate: self)
        transition.zoomedOutReferenceViewBorderWidth = CollectionViewTileCell.borderSize

        if dismissed is CollectionViewBackgroundTapTraitDelegate {
            transition.transitionDelay = CollectionViewBackgroundTapDuration + 0.1
        }

        let reference = animatedTransition(transition, snapshotReferenceViewWhenReversed: false)
        transition.zoomedOutFrame = reference.convert(reference.frame, to: nil)
        let borderSize = CollectionViewTileCell.borderSize
        transition.zoomedOutFrame = transition.zoomedOutFrame.insetBy(dx: -borderSize, dy: -borderSize)
        return transition
    }

    // MARK: - TransitionAnimationDelegate

    func animatedTransition(_ transition: AnimatedTransition,
                            snapshotReferenceViewWhenReversed reversed: Bool) -> UIView {
        let indexPath = delegate.currentIndexPath!
        let cell = collectionView.cellForItem(at: indexPath) ??
            collectionView.dataSource!.collectionView(collectionView, cellForItemAt: indexPath)
        guard cell is CollectionViewTileCell else {
            return delegate.animatedTransition!(transition, snapshotReferenceViewForCell: cell)
        }
        return cell
    }

    func animatedTransition(_ transition: AnimatedTransition,
                            willCreateSnapshotViewFromReferenceView reference: UIView) {
        guard let cell = reference as? CollectionViewTileCell else { return }
        switch transition {
        case is ZoomInTransition:
            cell.staticContentSubviews.forEach { $0.isHidden = true }
        case is ZoomOutTransition:
            if animatedTransition(transition, subviewsToAnimateSeparatelyForReferenceView: reference).count > 1 {
                cell.staticContentSubviews.forEach { $0.isHidden = true }
            }
        default: break
        }
    }

    func animatedTransition(_ transition: AnimatedTransition,
                            didCreateSnapshotView snapshot: UIView, fromReferenceView reference: UIView) {
        guard let cell = reference as? CollectionViewTileCell else { return }
        cell.staticContentSubviews.forEach { $0.isHidden = false }
    }

    func animatedTransition(_ transition: AnimatedTransition,
                            willTransitionWithSnapshotReferenceView reference: UIView, reversed: Bool) {
        guard let _ = transition as? ZoomTransition else { preconditionFailure() }
        if let cell = reference as? CollectionViewTileCell {
            cell.alpha = 0
        }
    }

    func animatedTransition(_ transition: AnimatedTransition,
                            didTransitionWithSnapshotReferenceView reference: UIView,
                            fromViewController: UIViewController, toViewController: UIViewController, reversed: Bool) {
        guard let _ = transition as? ZoomTransition else { preconditionFailure() }
        if let cell = reference as? CollectionViewTileCell {
            cell.alpha = 1
        }
    }

    func animatedTransition(_ transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceView reference: UIView) -> [UIView] {
        guard let cell = reference as? CollectionViewTileCell, transition is ZoomTransition else { return [] }
        return delegate.animatedTransition!(transition, subviewsToAnimateSeparatelyForReferenceCell: cell)
    }

    func animatedTransition(_ transition: AnimatedTransition,
                            subviewInDestinationViewController viewController: UIViewController,
                            forSubview subview: UIView) -> UIView? {
        let actualViewController = (viewController as? UINavigationController)?.topViewController ?? viewController
        return delegate.animatedTransition?(
            transition, subviewInDestinationViewController: actualViewController, forSubview: subview
        )
    }

}
