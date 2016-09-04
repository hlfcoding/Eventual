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
    func deleteDroppedCell(cellIndexPath: NSIndexPath)
    func minYForDraggingCell() -> CGFloat
    func maxYForDraggingCell() -> CGFloat
    optional func didCancelDraggingCellForDeletion(cellIndexPath: NSIndexPath)
    optional func didStartDraggingCellForDeletion(cellIndexPath: NSIndexPath)
    optional func willCancelDraggingCellForDeletion(cellIndexPath: NSIndexPath)
    optional func willStartDraggingCellForDeletion(cellIndexPath: NSIndexPath)

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

    // MARK: Initialization

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

    // MARK: Actions

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
            delegate.willStartDraggingCellForDeletion?(indexPath)
            detachCell(cell) {
                self.delegate.didStartDraggingCellForDeletion?(indexPath)
            }

        case .Cancelled, .Ended, .Failed:
            guard let indexPath = dragIndexPath else { preconditionFailure() }
            if delegate.canDeleteCellOnDropAtLocation(location) {
                dropCellAtLocation(location)
                delegate.deleteDroppedCell(indexPath)
            } else {
                guard let cell = collectionView.cellForItemAtIndexPath(indexPath) else { preconditionFailure() }
                delegate.willCancelDraggingCellForDeletion?(indexPath)
                reattachCell(cell) {
                    self.delegate.didCancelDraggingCellForDeletion?(indexPath)
                }
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

    // MARK: Subroutines

    private func constrainDragView() {
        guard let origin = dragOrigin, view = dragView else { preconditionFailure() }
        let boundsMinY = self.delegate.minYForDraggingCell()
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

    private func detachCell(cell: UICollectionViewCell, completion: (() -> Void)? = nil) {
        guard let origin = dragOrigin else { preconditionFailure() }

        let tileCell = cell as? CollectionViewTileCell
        tileCell?.toggleAllBorders(true)
        tileCell?.maintainInnerContentScale()
        let view = cell.snapshotViewAfterScreenUpdates(true)
        tileCell?.restoreOriginalBordersIfNeeded()

        view.center = origin
        view.layer.shadowColor = UIColor(white: 0, alpha: 0.4).CGColor
        view.layer.shadowOffset = CGSizeZero
        view.layer.shadowOpacity = 1
        collectionView.addSubview(view)
        dragView = view

        toggleDetachment(true) {
            tileCell?.isDetached = true
            self.offsetCellIfNeeded(cell)
            completion?()
        }
    }

    private func dropCellAtLocation(location: CGPoint) {
        guard let view = dragView else { return }
        UIView.animateWithDuration(0.3, animations: {
            // TODO
        }) { finished in
            view.removeFromSuperview()
        }
    }

    private func reattachCell(cell: UICollectionViewCell, completion: (() -> Void)? = nil) {
        guard let origin = dragOrigin, view = dragView else { preconditionFailure() }

        let tileCell = cell as? CollectionViewTileCell
        let duration = UIView.durationForAnimatingBetweenPoints((view.center, origin), withVelocity: 500)
        UIView.animateWithDuration(duration, animations: {
            view.center = origin
        }) { finished in
            self.toggleDetachment(false) {
                tileCell?.isDetached = false
                view.removeFromSuperview()
                completion?()
            }
        }
    }

    // MARK: Subroutines 2

    private func offsetCellIfNeeded(cell: UICollectionViewCell) {
        let offsetNeeded = cell.frame.maxY - delegate.maxYForDraggingCell()
        guard offsetNeeded > 0 else { return }
        var contentOffset = collectionView.contentOffset
        contentOffset.y += offsetNeeded
        collectionView.setContentOffset(contentOffset, animated: true)
    }

    private func toggleDetachment(visible: Bool, completion: (() -> Void)? = nil) {
        guard let view = dragView else { preconditionFailure() }
        let radius: CGFloat = visible ? 10 : 0
        let scale: CGFloat = visible ? (round(view.frame.width * 1.03) / view.frame.width) : 1
        let timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        let scaleAnimation: CABasicAnimation!
        if visible {
            let springAnimation = CASpringAnimation(keyPath: "transform.scale")
            springAnimation.damping = 1
            springAnimation.initialVelocity = 5
            scaleAnimation = springAnimation
        } else {
            scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.timingFunction = timingFunction
        }
        scaleAnimation.fromValue = view.transform.a
        scaleAnimation.toValue = scale

        let shadowAnimation = CABasicAnimation(keyPath: "shadowRadius")
        shadowAnimation.fromValue = view.layer.shadowRadius
        shadowAnimation.toValue = radius
        shadowAnimation.timingFunction = timingFunction

        view.layer.shadowRadius = radius
        view.transform = CGAffineTransformMakeScale(scale, scale)
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        CATransaction.setCompletionBlock(completion)
        view.layer.addAnimation(scaleAnimation, forKey: "scale")
        view.layer.addAnimation(shadowAnimation, forKey: "shadow")
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