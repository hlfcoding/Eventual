//
//  CollectionViewDragDropDeletionTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

// MARK: CollectionViewDragDropDeletionTraitDelegate

@objc protocol CollectionViewDragDropDeletionTraitDelegate {

    var collectionView: UICollectionView? { get }

    func canDeleteCellOnDropAtLocation(location: CGPoint) -> Bool
    func deleteDroppedCellAtIndexPath(indexPath: NSIndexPath)
    func willCancelDraggingCellAtIndexPath(indexPath: NSIndexPath)
    func willStartDraggingCellAtIndexPath(indexPath: NSIndexPath)

}

// MARK: -

class CollectionViewDragDropDeletionTrait: NSObject {

    private(set) weak var delegate: CollectionViewDragDropDeletionTraitDelegate!

    private var collectionView: UICollectionView! { return delegate.collectionView! }

    private var longPressRecognizer: UILongPressGestureRecognizer!
    private var panRecognizer: UIPanGestureRecognizer!

    private var dragIndexPath: NSIndexPath?
    private var dragOrigin: CGPoint?
    private var dragView: UIView?

    init(delegate: CollectionViewDragDropDeletionTraitDelegate) {
        super.init()
        self.delegate = delegate
        setUpRecognizers()
    }

    private func setUpRecognizers() {
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressRecognizer.delegate = self
        collectionView.addGestureRecognizer(longPressRecognizer)

        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panRecognizer.delegate = self
        collectionView.addGestureRecognizer(panRecognizer)
    }

    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        guard sender === longPressRecognizer else { preconditionFailure() }
        let location = longPressRecognizer.locationInView(collectionView)
        switch longPressRecognizer.state {

        case .Began:
            guard let
                indexPath = collectionView.indexPathForItemAtPoint(location),
                cell = collectionView.cellForItemAtIndexPath(indexPath)
                else { return }
            dragIndexPath = indexPath
            dragOrigin = cell.center
            delegate.willStartDraggingCellAtIndexPath(indexPath)
            detachCell(cell)

        case .Cancelled, .Ended, .Failed:
            guard let indexPath = dragIndexPath else { preconditionFailure() }
            if delegate.canDeleteCellOnDropAtLocation(location) {
                dropCellAtLocation(location)
                delegate.deleteDroppedCellAtIndexPath(indexPath)
            } else {
                delegate.willCancelDraggingCellAtIndexPath(indexPath)
                reattachCell()
            }
            dragIndexPath = nil

        case .Changed, .Possible: break
        }
    }

    @objc private func handlePan(sender: UIPanGestureRecognizer) {
        guard sender === panRecognizer else { preconditionFailure() }
        switch panRecognizer.state {

        case .Changed:
            guard let dragOrigin = dragOrigin, dragView = dragView else { preconditionFailure() }
            let translation = panRecognizer.translationInView(collectionView)
            dragView.center = dragOrigin
            dragView.center.x += translation.x
            dragView.center.y += translation.y
            constrainDragView()

        case .Began, .Cancelled, .Ended, .Failed, .Possible: break
        }
    }

    private func constrainDragView() {
        guard let origin = dragOrigin, view = dragView else { preconditionFailure() }
        let boundsMinY = collectionView.bounds.minY + ((collectionView.collectionViewLayout as? CollectionViewTileLayout)?
            .viewportYOffset ?? 0)
        if (view.frame.minX < collectionView.bounds.minX ||
            view.frame.maxX > collectionView.bounds.maxX) {
            view.center.x = origin.x
        }
        if view.frame.minY < boundsMinY {
            view.frame.origin.y = boundsMinY
        } else if view.frame.maxY > collectionView.bounds.maxY {
            view.frame.origin.y = collectionView.bounds.maxY - view.frame.height
        }
    }

    private func detachCell(cell: UICollectionViewCell) {
        guard let origin = dragOrigin else { preconditionFailure() }

        let tileCell = cell as? CollectionViewTileCell
        tileCell?.toggleAllBorders(true)

        let view = cell.snapshotViewAfterScreenUpdates(true)
        view.center = origin
        view.layer.shadowColor = UIColor(white: 0, alpha: 0.5).CGColor
        view.layer.shadowOffset = CGSizeZero
        view.layer.shadowOpacity = 1
        collectionView.addSubview(view)
        dragView = view
        toggleDetachedShadow(true)

        tileCell?.restoreOriginalBordersIfNeeded()
    }

    private func dropCellAtLocation(location: CGPoint) {
        guard let view = dragView else { return }
        UIView.animateWithDuration(0.3, animations: {
            // TODO
        }) { finished in
            view.removeFromSuperview()
        }
    }

    private func reattachCell() {
        guard let origin = dragOrigin, view = dragView else { preconditionFailure() }
        let duration = UIView.durationForAnimatingBetweenPoints((view.center, origin), withVelocity: 500)
        UIView.animateWithDuration(duration, animations: {
            view.center = origin
        }) { finished in
            self.toggleDetachedShadow(false) {
                view.removeFromSuperview()
            }
        }
    }

    private func toggleDetachedShadow(visible: Bool, completion: (() -> Void)? = nil) {
        guard let view = dragView else { preconditionFailure() }
        let radius: CGFloat = visible ? 8 : 0

        let animation = CABasicAnimation(keyPath: "shadowRadius")
        animation.fromValue = view.layer.shadowRadius
        animation.toValue = radius
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        CATransaction.begin()
        view.layer.shadowRadius = radius
        CATransaction.setCompletionBlock(completion)
        view.layer.addAnimation(animation, forKey: "shadowRadius")
        CATransaction.commit()
    }

}

// MARK: - UIGestureRecognizerDelegate

extension CollectionViewDragDropDeletionTrait: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        switch gestureRecognizer {
        case panRecognizer: return dragIndexPath != nil
        default: return true
        }
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        switch (gestureRecognizer, otherGestureRecognizer) {
        case (longPressRecognizer, panRecognizer): return true
        case (panRecognizer, longPressRecognizer): return true
        default: return false
        }
    }

}