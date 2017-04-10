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

    func canDeleteCellOnDrop(cellFrame: CGRect) -> Bool
    func deleteDroppedCell(_ cell: UIView, completion: () -> Void) throws
    func finalFrameForDroppedCell() -> CGRect
    func minYForDraggingCell() -> CGFloat
    func maxYForDraggingCell() -> CGFloat
    @objc optional func canDragCell(at cellIndexPath: IndexPath) -> Bool
    @objc optional func didCancelDraggingCellForDeletion(at cellIndexPath: IndexPath)
    @objc optional func didRemoveDroppedCellAfterDeletion(at cellIndexPath: IndexPath)
    @objc optional func didStartDraggingCellForDeletion(at cellIndexPath: IndexPath)
    @objc optional func willCancelDraggingCellForDeletion(at cellIndexPath: IndexPath)
    @objc optional func willStartDraggingCellForDeletion(at cellIndexPath: IndexPath)

}

// MARK: -

class CollectionViewDragDropDeletionTrait: NSObject {

    private(set) weak var delegate: CollectionViewDragDropDeletionTraitDelegate!

    private var collectionView: UICollectionView! { return delegate.collectionView! }

    fileprivate var longPressRecognizer: UILongPressGestureRecognizer!
    fileprivate var panRecognizer: UIPanGestureRecognizer!

    fileprivate var dragIndexPath: IndexPath?
    private var dragOrigin: CGPoint?
    private var dragView: UIView?

    private var dragViewCanReattach = false
    private var dragViewNeedsReattach = false

    // MARK: Initialization

    init(delegate: CollectionViewDragDropDeletionTraitDelegate) {
        super.init()
        self.delegate = delegate
        setUpRecognizers()
    }

    private func setUpRecognizers() {
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        longPressRecognizer.delegate = self
        collectionView.addGestureRecognizer(longPressRecognizer)

        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(sender:)))
        panRecognizer.delegate = self
        collectionView.addGestureRecognizer(panRecognizer)
    }

    // MARK: Actions

    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        guard sender === longPressRecognizer else { preconditionFailure() }
        let location = longPressRecognizer.location(in: collectionView)

        let handleReattach = { (cell: UICollectionViewCell, indexPath: IndexPath) in
            guard self.dragViewCanReattach else {
                self.dragViewNeedsReattach = true
                return
            }
            self.dragViewCanReattach = false
            self.delegate.willCancelDraggingCellForDeletion?(at: indexPath)
            self.reattachCell(cell) {
                self.delegate.didCancelDraggingCellForDeletion?(at: indexPath)
            }
        }

        switch longPressRecognizer.state {

        case .began:
            guard let indexPath = collectionView.indexPathForItem(at: location),
                let cell = collectionView.cellForItem(at: indexPath),
                delegate.canDragCell?(at: indexPath) ?? true
                else { return }
            dragIndexPath = indexPath
            dragOrigin = cell.center
            delegate.willStartDraggingCellForDeletion?(at: indexPath)
            let handleDetach = {
                self.detachCell(cell) {
                    self.dragViewCanReattach = true
                    if self.dragViewNeedsReattach {
                        self.dragViewNeedsReattach = false
                        handleReattach(cell, indexPath)
                        return
                    }
                    self.delegate.didStartDraggingCellForDeletion?(at: indexPath)
                }
            }
            if let tileCell = cell as? CollectionViewTileCell {
                tileCell.animateUnhighlighted(completion: handleDetach)
            } else {
                handleDetach()
            }

        case .cancelled, .ended, .failed:
            guard let indexPath = dragIndexPath, let dragView = dragView,
                let cell = collectionView.cellForItem(at: indexPath)
                else { return }
            defer {
                dragIndexPath = nil
            }
            guard delegate.canDeleteCellOnDrop(cellFrame: dragView.frame) else {
                handleReattach(cell, indexPath)
                return
            }
            let handleRemove = {
                self.removeCell(cell) {
                    self.delegate.didRemoveDroppedCellAfterDeletion?(at: indexPath)
                }
            }
            let handleDelete = {
                do {
                    try self.delegate.deleteDroppedCell(dragView, completion: handleRemove)
                } catch {
                    handleReattach(cell, indexPath)
                }
            }
            dropCell(cell, completion: handleDelete)

        case .changed, .possible: break
        }
    }

    @objc private func handlePan(sender: UIPanGestureRecognizer) {
        guard sender === panRecognizer else { preconditionFailure() }
        switch panRecognizer.state {

        case .changed:
            guard let dragOrigin = dragOrigin, let dragView = dragView else { preconditionFailure() }
            let translation = panRecognizer.translation(in: collectionView)
            dragView.center = dragOrigin
            dragView.center.x += translation.x
            dragView.center.y += translation.y
            constrainDragView()
            toggleCellDroppable(delegate.canDeleteCellOnDrop(cellFrame: dragView.frame))

        case .began, .cancelled, .ended, .failed, .possible: break
        }
    }

    // MARK: Subroutines

    private func constrainDragView() {
        var bounds = collectionView.bounds
        let offsetY = delegate.minYForDraggingCell() - bounds.minY
        bounds.origin.y += offsetY
        bounds.size.height -= offsetY
        dragView!.frame.constrainInPlace(inside: bounds)
    }

    private func detachCell(_ cell: UICollectionViewCell, completion: @escaping () -> Void) {
        let view = cell.snapshotView(afterScreenUpdates: false)
        (cell as? CollectionViewTileCell)?.isDetached = true

        view!.center = dragOrigin!
        view!.layer.shadowColor = UIColor(white: 0, alpha: 0.4).cgColor
        view!.layer.shadowOffset = .zero
        view!.layer.shadowOpacity = 1
        collectionView.addSubview(view!)
        dragView = view

        toggleDetachment(visible: true) {
            self.offsetCellIfNeeded(cell)
            completion()
        }
    }

    private func dropCell(_ cell: UICollectionViewCell, completion: @escaping () -> Void) {
        guard let view = dragView else { return }

        UIView.animate(withDuration: 0.3, animations: {
            view.transform = .identity
        }) { finished in
            completion()
        }
    }

    private func reattachCell(_ cell: UICollectionViewCell, completion: @escaping () -> Void) {
        guard let origin = dragOrigin, let view = dragView else { preconditionFailure() }

        let duration = UIView.durationForAnimatingBetweenPoints((view.center, origin), withVelocity: 500)
        UIView.animate(withDuration: duration, animations: {
            view.center = origin
        }) { finished in
            self.toggleDetachment(visible: false) {
                (cell as? CollectionViewTileCell)?.isDetached = false
                view.removeFromSuperview()
                completion()
            }
        }
    }

    private func removeCell(_ cell: UICollectionViewCell, completion: @escaping () -> Void) {
        guard let view = dragView else { preconditionFailure() }

        UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseIn, animations: {
            view.alpha = 0
            view.frame = self.delegate.finalFrameForDroppedCell()
        }) { finished in
            view.removeFromSuperview()
            completion()
        }
    }

    private func toggleCellDroppable(_ droppable: Bool) {
        guard let view = dragView else { preconditionFailure() }
        let alpha: CGFloat = droppable ? 0.8 : 1
        guard alpha != view.alpha else { return }
        UIView.animate(withDuration: 0.3) {
            view.alpha = alpha
        }
    }

    // MARK: Subroutines 2

    private func offsetCellIfNeeded(_ cell: UICollectionViewCell) {
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

        let shadowAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.shadowRadius))
        shadowAnimation.fromValue = view.layer.shadowRadius
        shadowAnimation.toValue = radius
        shadowAnimation.timingFunction = timingFunction

        view.layer.shadowRadius = radius
        view.transform = CGAffineTransform(scaleX: scale, y: scale)
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        CATransaction.setCompletionBlock(completion)
        view.layer.add(scaleAnimation, forKey: "scale")
        view.layer.add(shadowAnimation, forKey: "shadow")
        CATransaction.commit()
    }

}

// MARK: - UIGestureRecognizerDelegate

extension CollectionViewDragDropDeletionTrait: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        switch gestureRecognizer {
        case panRecognizer: return dragIndexPath != nil
        default: return true
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        switch (gestureRecognizer, otherGestureRecognizer) {
        case (longPressRecognizer, panRecognizer): return true
        case (panRecognizer, longPressRecognizer): return true
        default: return false
        }
    }

}
