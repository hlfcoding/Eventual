//
//  CollectionViewZoomTransitionTrait.swift
//  Eventual
//
//  Created by Peng Wang on 12/20/14.
//  Copyright (c) 2014-2016 Eventual App. All rights reserved.
//

import UIKit

@objc(ETCollectionViewZoomTransitionTraitDelegate) protocol CollectionViewZoomTransitionTraitDelegate: NSObjectProtocol {

    var collectionView: UICollectionView? { get }
    var currentIndexPath: NSIndexPath? { get set }

    func animatedTransition(transition: AnimatedTransition,
         subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView]

    optional func animatedTransition(transition: AnimatedTransition,
                  subviewInDestinationViewController viewController: UIViewController,
                  forSubview subview: UIView) -> UIView?

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
         withSnapshotReferenceCell cell: CollectionViewTileCell)

}

class CollectionViewZoomTransitionTrait: NSObject, UIViewControllerTransitioningDelegate,
                                         TransitionAnimationDelegate, TransitionInteractionDelegate
{

    private(set) weak var delegate: CollectionViewZoomTransitionTraitDelegate!

    private var collectionView: UICollectionView! { return self.delegate.collectionView! }

    var isInteractive = false
    var isInteractionEnabled: Bool {
        get {
            return self.interactionController.isEnabled ?? false
        }
        set(newValue) {
            if let interactionController = self.interactionController {
                interactionController.isEnabled = newValue ?? false
            }
        }
    }
    private var interactionController: InteractiveZoomTransition!

    init(delegate: CollectionViewZoomTransitionTraitDelegate) {
        super.init()
        self.delegate = delegate

        self.initInteractionController()
    }

    private func initInteractionController() {
        guard let source = self.delegate as? UICollectionViewController
              else { assertionFailure("Source must be UICollectionViewController."); return }

        var reverseDelegate: TransitionInteractionDelegate?
        if let collectionViewController = self.presentingViewControllerForViewController(source) as? UICollectionViewController,
               zoomTransitionTrait = collectionViewController.valueForKey("zoomTransitionTrait") as? CollectionViewZoomTransitionTrait
        {
            reverseDelegate = zoomTransitionTrait
        }

        self.interactionController = InteractiveZoomTransition(delegate: self, reverseDelegate: reverseDelegate)
        self.interactionController.pinchWindow = UIApplication.sharedApplication().keyWindow!
        self.isInteractive = self.interactionController != nil
    }

    // MARK: - UIViewControllerTransitioningDelegate

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController,
         sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        let transition = ZoomInTransition(delegate: self)
        let offset = self.collectionView.contentOffset
        let cell = self.animatedTransition(transition, snapshotReferenceViewWhenReversed: false)
        transition.zoomedOutFrame = CGRectOffset(cell.frame, -offset.x, -offset.y)
        return transition
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let source = self.presentingViewControllerForViewController(dismissed) as? UICollectionViewController
              else { assertionFailure("Source must be UICollectionViewController."); return nil }

        let transition = ZoomOutTransition(delegate: self)
        let offset = source.collectionView!.contentOffset
        let cell = self.animatedTransition(transition, snapshotReferenceViewWhenReversed: true)
        transition.zoomedOutFrame = CGRectOffset(cell.frame, -offset.x, -offset.y)

        return transition
    }

    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard self.isInteractive else { return nil }
        return self.interactionController
    }

    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard self.isInteractive else { return nil }
        return self.interactionController
    }

    // MARK: - TransitionAnimationDelegate

    func animatedTransition(transition: AnimatedTransition,
         snapshotReferenceViewWhenReversed reversed: Bool) -> UIView
    {
        guard let indexPath = self.delegate.currentIndexPath else { return self.collectionView }
        return self.collectionView.guaranteedCellForItemAtIndexPath(indexPath)
    }

    func animatedTransition(transition: AnimatedTransition,
         willCreateSnapshotViewFromReferenceView reference: UIView)
    {
        guard let cell = reference as? CollectionViewTileCell else { return }

        switch transition {
        case is ZoomInTransition:
            cell.toggleAllBorders(false)
            cell.staticContentSubviews.forEach { $0.hidden = true }
        case is ZoomOutTransition:
            cell.toggleAllBorders(true)
            if self.animatedTransition(transition, subviewsToAnimateSeparatelyForReferenceView: reference).count > 1 {
                cell.staticContentSubviews.forEach { $0.hidden = true }
            }
        default: break
        }
    }

    func animatedTransition(transition: AnimatedTransition,
         didCreateSnapshotView snapshot: UIView, fromReferenceView reference: UIView)
    {
        guard let cell = reference as? CollectionViewTileCell else { return }
        cell.restoreOriginalBordersIfNeeded()

        switch transition {
        case is ZoomInTransition:
            cell.addBordersToSnapshotView(snapshot)
            cell.staticContentSubviews.forEach { $0.hidden = false }
        case is ZoomOutTransition:
            cell.staticContentSubviews.forEach { $0.hidden = false }
        default: break
        }
    }

    func animatedTransition(transition: AnimatedTransition,
         willTransitionWithSnapshotReferenceView reference: UIView, reversed: Bool)
    {
        guard let cell = reference as? CollectionViewTileCell where transition is ZoomTransition else { return }
        // TODO: Neighboring cells can end up temporarily missing borders.
        cell.alpha = 0.0
    }

    func animatedTransition(transition: AnimatedTransition,
         didTransitionWithSnapshotReferenceView reference: UIView, reversed: Bool)
    {
        guard let cell = reference as? CollectionViewTileCell where transition is ZoomTransition else { return }
        cell.alpha = 1.0
    }

    func animatedTransition(transition: AnimatedTransition,
         subviewsToAnimateSeparatelyForReferenceView reference: UIView) -> [UIView]
    {
        guard let cell = reference as? CollectionViewTileCell where transition is ZoomTransition else { return [] }
        return self.delegate.animatedTransition(transition, subviewsToAnimateSeparatelyForReferenceCell: cell)
    }

    func animatedTransition(transition: AnimatedTransition,
         var subviewInDestinationViewController viewController: UIViewController,
         forSubview subview: UIView) -> UIView?
    {
        if let navigationController = viewController as? NavigationViewController {
            viewController = navigationController.topViewController!
        }
        return self.delegate.animatedTransition?( transition,
            subviewInDestinationViewController: viewController, forSubview: subview)
    }

    // MARK: TransitionInteractionDelegate

    func interactiveTransition(transition: InteractiveTransition,
         locationContextViewForGestureRecognizer recognizer: UIGestureRecognizer) -> UIView
    {
        return self.collectionView
    }

    func interactiveTransition(transition: InteractiveTransition,
         snapshotReferenceViewAtLocation location: CGPoint, ofContextView contextView: UIView) -> UIView?
    {
        guard let indexPath = self.collectionView.indexPathForItemAtPoint(location) else { return nil }
        return self.collectionView.guaranteedCellForItemAtIndexPath(indexPath)
    }

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)
    {
        guard let cell = referenceView as? CollectionViewTileCell,
                  indexPath = self.collectionView.indexPathForCell(cell)
              else { return }

        self.delegate.currentIndexPath = indexPath
    }

    func beginInteractiveDismissalTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)
    {
        self.isInteractive = true
        // TODO
    }

    func interactiveTransition(transition: InteractiveTransition,
         destinationScaleForSnapshotReferenceView referenceView: UIView?,
         contextView: UIView, reversed: Bool) -> CGFloat
    {
        guard let zoomTransition = transition as? InteractiveZoomTransition,
                  indexPath = self.delegate.currentIndexPath
              else { return -1.0 }
        let cell = self.collectionView.guaranteedCellForItemAtIndexPath(indexPath)
        return cell.frame.width / zoomTransition.pinchSpan
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
