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

    @objc optional func zoomTransitionFrameFitting(_ transition: ZoomTransition) -> String?

    @objc optional func zoomTransition(_ transition: ZoomTransition,
                                       subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView]

    @objc optional func zoomTransition(_ transition: ZoomTransition,
                                       subviewInDestinationViewController viewController: UIViewController,
                                       forSubview subview: UIView) -> UIView?

    @objc optional func zoomTransition(_ transition: ZoomTransition,
                                       snapshotReferenceViewForCell cell: UICollectionViewCell) -> UIView

}

class CollectionViewZoomTransitionTrait: NSObject,
UIViewControllerTransitioningDelegate, ZoomTransitionDelegate {

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
        let reference = zoomTransitionSnapshotReferenceView(transition)
        transition.zoomedOutFrame = snapshotReferenceViewFrame(reference)
        if reference is CollectionViewTileCell {
            transition.zoomedOutReferenceViewBorderWidth = CollectionViewTileCell.borderSize
        }
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = ZoomOutTransition(delegate: self)

        if dismissed is CollectionViewBackgroundTapTraitDelegate {
            transition.transitionDelay = CollectionViewBackgroundTapDuration + 0.1
        }

        let reference = zoomTransitionSnapshotReferenceView(transition)
        transition.zoomedOutFrame = snapshotReferenceViewFrame(reference)
        if reference is CollectionViewTileCell {
            let borderSize = CollectionViewTileCell.borderSize
            transition.zoomedOutReferenceViewBorderWidth = borderSize
            transition.zoomedOutFrame = transition.zoomedOutFrame.insetBy(dx: -borderSize, dy: -borderSize)
        }
        return transition
    }

    private func snapshotReferenceViewFrame(_ reference: UIView) -> CGRect {
        if reference is UICollectionViewCell {
            // NOTE: Not sure why yet, but it works.
            let offset = collectionView.contentOffset
            return reference.frame.offsetBy(dx: -offset.x, dy: -offset.y)
        }
        return reference.convert(reference.frame, to: nil)
    }

    // MARK: - ZoomTransitionDelegate

    func zoomTransitionSnapshotReferenceView(_ transition: ZoomTransition) -> UIView {
        let indexPath = delegate.currentIndexPath!
        let cell = collectionView.cellForItem(at: indexPath) ??
            collectionView.dataSource!.collectionView(collectionView, cellForItemAt: indexPath)
        guard cell is CollectionViewTileCell else {
            return delegate.zoomTransition!(transition, snapshotReferenceViewForCell: cell)
        }
        return cell
    }

    func zoomTransitionFrameFitting(_ transition: ZoomTransition) -> String? {
        return delegate.zoomTransitionFrameFitting?(transition)
    }

    func zoomTransition(_ transition: ZoomTransition,
                        willCreateSnapshotViewFromReferenceView reference: UIView) {
        guard let cell = reference as? CollectionViewTileCell else { return }
        switch transition {
        case is ZoomInTransition:
            cell.staticContentSubviews.forEach { $0.isHidden = true }
        case is ZoomOutTransition:
            if zoomTransition(transition, subviewsToAnimateSeparatelyForReferenceView: reference).count > 1 {
                cell.staticContentSubviews.forEach { $0.isHidden = true }
            }
        default: break
        }
    }

    func zoomTransition(_ transition: ZoomTransition,
                        didCreateSnapshotView snapshot: UIView, fromReferenceView reference: UIView) {
        guard let cell = reference as? CollectionViewTileCell else { return }
        cell.staticContentSubviews.forEach { $0.isHidden = false }
    }

    func zoomTransitionWillTransition(_ transition: ZoomTransition) {
        if let cell = transition.zoomedOutView as? CollectionViewTileCell {
            cell.alpha = 0
        }
    }

    func zoomTransitionDidTransition(_ transition: ZoomTransition) {
        if let cell = transition.zoomedOutView as? CollectionViewTileCell {
            cell.alpha = 1
        }
    }

    func zoomTransition(_ transition: ZoomTransition,
                        subviewsToAnimateSeparatelyForReferenceView reference: UIView) -> [UIView] {
        guard let cell = reference as? CollectionViewTileCell else { return [] }
        return delegate.zoomTransition!(transition, subviewsToAnimateSeparatelyForReferenceCell: cell)
    }

    func zoomTransition(_ transition: ZoomTransition,
                        subviewInDestinationViewController viewController: UIViewController,
                        forSubview subview: UIView) -> UIView? {
        let actualViewController = (viewController as? UINavigationController)?.topViewController ?? viewController
        return delegate.zoomTransition?(
            transition, subviewInDestinationViewController: actualViewController, forSubview: subview
        )
    }

}
