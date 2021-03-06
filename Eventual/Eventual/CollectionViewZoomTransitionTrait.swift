//
//  CollectionViewZoomTransitionTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@objc protocol CollectionViewZoomTransitionTraitDelegate: CollectionViewTraitDelegate {

    var currentIndexPath: IndexPath? { get set }

    @objc optional func zoomTransitionFrameFitting(_ transition: ZoomTransition) -> String

    @objc optional func zoomTransitionViewIntersection(_ transition: ZoomTransition) -> String

    @objc optional func zoomTransition(_ transition: ZoomTransition,
                                       originForZoomedOutFrameZoomedIn frame: CGRect) -> CGPoint

    @objc optional func zoomTransition(_ transition: ZoomTransition,
                                       originForZoomedInFrameZoomedOut frame: CGRect) -> CGPoint

    @objc optional func zoomTransition(_ transition: ZoomTransition,
                                       subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView]

    @objc optional func zoomTransition(_ transition: ZoomTransition,
                                       subviewInDestinationViewController viewController: UIViewController,
                                       forSubview subview: UIView) -> UIView?

    @objc optional func zoomTransition(_ transition: ZoomTransition,
                                       snapshotReferenceViewForCell cell: UICollectionViewCell) -> UIView

    @objc optional func zoomTransition(_ transition: ZoomTransition,
                                       viewForCell cell: UICollectionViewCell) -> UIView

}

final class CollectionViewZoomTransitionTrait: NSObject,
UIViewControllerTransitioningDelegate, ZoomTransitionDelegate {

    private(set) weak var delegate: CollectionViewZoomTransitionTraitDelegate!

    private var collectionView: UICollectionView! { return delegate.collectionView! }

    private var cell: UICollectionViewCell! {
        let indexPath = delegate.currentIndexPath!
        return collectionView.cellForItem(at: indexPath) ??
            collectionView.dataSource!.collectionView(collectionView, cellForItemAt: indexPath)
    }

    private weak var zoomedOutReference: UIView?
    private var zoomedOutView: UIView?

    init(delegate: CollectionViewZoomTransitionTraitDelegate) {
        super.init()
        self.delegate = delegate
    }

    // MARK: - UIViewControllerTransitioningDelegate

    func animationController(forPresented presented: UIViewController, presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = ZoomInTransition(delegate: self)
        let reference = zoomedOutReferenceView(transition)
        transition.zoomedOutFrame = zoomedOutReferenceViewFrame(reference)
        if reference is CollectionViewTileCell {
            transition.zoomedOutViewBorderWidth = CollectionViewTileCell.borderSize
        }
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = ZoomOutTransition(delegate: self)

        if dismissed is CollectionViewBackgroundTapTraitDelegate {
            transition.transitionDelay = CollectionViewBackgroundTapDuration + 0.1
        }

        let reference = zoomedOutReferenceView(transition)
        transition.zoomedOutFrame = zoomedOutReferenceViewFrame(reference)
        if reference is CollectionViewTileCell {
            let borderSize = CollectionViewTileCell.borderSize
            transition.zoomedOutViewBorderWidth = borderSize
            transition.zoomedOutFrame = transition.zoomedOutFrame.insetBy(dx: -borderSize, dy: -borderSize)
        }
        return transition
    }

    private func zoomedOutReferenceView(_ transition: ZoomTransition) -> UIView {
        if let _ = zoomTransitionView(transition) {
            return zoomedOutReference!
        } else {
            return zoomTransitionSnapshotReferenceView(transition)
        }
    }

    private func zoomedOutReferenceViewFrame(_ reference: UIView) -> CGRect {
        guard let window = reference.window, let superview = reference.superview else {
            return reference.frame
        }
        return window.convert(reference.frame, from: superview)
    }

    // MARK: - ZoomTransitionDelegate

    func zoomTransitionView(_ transition: ZoomTransition) -> UIView? {
        guard let reference = delegate.zoomTransition?(transition, viewForCell: cell) as? MonthTilesView else {
            return nil
        }
        zoomedOutReference = reference
        zoomedOutView = MonthTilesView(reference: reference)
        return zoomedOutView
    }

    func zoomTransitionSnapshotReferenceView(_ transition: ZoomTransition) -> UIView {
        return delegate.zoomTransition?(transition, snapshotReferenceViewForCell: cell) ?? cell
    }

    func zoomTransitionFrameFitting(_ transition: ZoomTransition) -> ZoomTransitionFrameFitting? {
        guard let rawValue = delegate.zoomTransitionFrameFitting?(transition) else { return nil }
        return ZoomTransitionFrameFitting(rawValue: rawValue)
    }

    func zoomTransitionViewIntersection(_ transition: ZoomTransition) -> ZoomTransitionViewIntersection? {
        guard let rawValue = delegate.zoomTransitionViewIntersection?(transition) else { return nil }
        return ZoomTransitionViewIntersection(rawValue: rawValue)
    }

    func zoomTransition(_ transition: ZoomTransition,
                        originForZoomedOutFrameZoomedIn frame: CGRect) -> CGPoint {
        // NOTE: Using `??` causes 'Segmentation Fault 11' in Swift compiler (8.2.1).
        guard delegate.responds(to: #selector(zoomTransition(_:originForZoomedOutFrameZoomedIn:)))
            else { return frame.origin }
        return delegate.zoomTransition!(transition, originForZoomedOutFrameZoomedIn: frame)
    }

    func zoomTransition(_ transition: ZoomTransition,
                        originForZoomedInFrameZoomedOut frame: CGRect) -> CGPoint {
        // NOTE: Using `??` causes 'Segmentation Fault 11' in Swift compiler (8.2.1).
        guard delegate.responds(to: #selector(zoomTransition(_:originForZoomedInFrameZoomedOut:)))
            else { return frame.origin }
        return delegate.zoomTransition!(transition, originForZoomedInFrameZoomedOut: frame)
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
        let view = zoomedOutReference ?? transition.zoomedOutView
        view!.alpha = 0
    }

    func zoomTransitionDidTransition(_ transition: ZoomTransition) {
        let view = zoomedOutReference ?? transition.zoomedOutView
        view!.alpha = 1
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
