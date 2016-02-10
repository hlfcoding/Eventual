//
//  DayViewController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import EventKit

class DayViewController: UICollectionViewController {

    // MARK: State

    private var currentIndexPath: NSIndexPath?

    // MARK: Add Event

    @IBOutlet private var backgroundTapRecognizer: UITapGestureRecognizer!
    var backgroundTapTrait: CollectionViewBackgroundTapTrait!

    // MARK: Data Source

    var dayDate: NSDate!
    private var events: [Event]!
    private var eventManager: EventManager { return EventManager.defaultManager }

    // MARK: Layout

    private var tileLayout: CollectionViewTileLayout {
        return self.collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: Navigation

    private var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: - Initializers

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setUp()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }

    deinit {
        self.tearDown()
    }

    private func setUp() {
        self.customizeNavigationItem()

        let center = NSNotificationCenter.defaultCenter()
        center.addObserver( self,
            selector: Selector("entitySaveOperationDidComplete:"),
            name: EntitySaveOperationNotification, object: nil
        )
    }
    private func tearDown() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAccessibilityLabels()
        // Data.
        self.updateData()
        // Title.
        self.title = NSDateFormatter.monthDayFormatter.stringFromDate(self.dayDate)
        self.customizeNavigationItem() // Hacky sync.
        // Transition.
        self.zoomTransitionTrait = CollectionViewZoomTransitionTrait(
            collectionView: self.collectionView!,
            animationDelegate: self,
            interactionDelegate: self
        )
        // Layout customization.
        self.tileLayout.dynamicNumberOfColumns = false
        // Traits.
        self.backgroundTapTrait = CollectionViewBackgroundTapTrait(
            delegate: self,
            collectionView: self.collectionView!,
            tapRecognizer: self.backgroundTapRecognizer
        )
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.zoomTransitionTrait.isInteractionEnabled = true
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.backgroundTapTrait.updateOnAppearance(true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.backgroundTapTrait.updateOnAppearance(true, reverse: true)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.presentedViewController == nil {
            self.zoomTransitionTrait.isInteractionEnabled = false
        }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({ (context) in
            self.tileLayout.invalidateLayout()
        }, completion: nil)
    }

    private func setAccessibilityLabels() {
        self.collectionView!.accessibilityLabel = t(Label.DayEvents.rawValue)
    }

    // MARK: Handlers

    func entitySaveOperationDidComplete(notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard (notification.userInfo?[TypeKey] as? UInt) == EKEntityType.Event.rawValue else { return }
        self.updateData()
        self.collectionView!.reloadData()
    }
}

// MARK: - Navigation

extension DayViewController: TransitionAnimationDelegate, TransitionInteractionDelegate,
                             CollectionViewBackgroundTapTraitDelegate
{

    // MARK: Actions

    @IBAction private func unwindToDay(sender: UIStoryboardSegue) {
        if let navigationController = self.presentedViewController as? NavigationController,
               indexPath = self.currentIndexPath
        {
            // Just do the default transition if the snapshotReferenceView is illegitimate.
            self.eventManager.updateEventsByMonthsAndDays() // FIXME
            self.updateData()
            if self.events?.count > indexPath.item,
               let event = self.events?[indexPath.item] where event.startDate != self.dayDate // Is date modified?
            {
                self.collectionView!.reloadData()
            }
            navigationController.transitioningDelegate = nil
            navigationController.modalPresentationStyle = .FullScreen
        }
    }

    // MARK: CollectionViewBackgroundTapTraitDelegate

    func backgroundTapTraitDidToggleHighlight() {
        self.performSegueWithIdentifier(Segue.AddEvent.rawValue, sender: self.backgroundTapTrait)
    }

    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        guard let rawIdentifier = segue.identifier,
                  identifier = Segue(rawValue: rawIdentifier),
                  navigationController = segue.destinationViewController as? NavigationController,
                  viewController = navigationController.topViewController as? EventViewController
              else { return }

        switch identifier {

        case .AddEvent:
            self.currentIndexPath = nil // Reset.

            let event = Event(entity: EKEvent(eventStore: self.eventManager.store))
            event.title = ""
            event.startDate = self.dayDate
            viewController.event = event
            viewController.newEventStartDate = self.dayDate
            viewController.unwindSegueIdentifier = .UnwindToDay

        case .EditEvent:
            navigationController.transitioningDelegate = self.zoomTransitionTrait
            navigationController.modalPresentationStyle = .Custom
            if sender is EventViewCell {
                self.zoomTransitionTrait.isInteractive = false
            }

            guard let indexPath = self.currentIndexPath else { break }
            if let event = self.events?[indexPath.item] {
                viewController.event = event
            }
            viewController.unwindSegueIdentifier = .UnwindToDay

        default: assertionFailure("Unsupported segue \(identifier).")
        }
    }

    // MARK: TransitionAnimationDelegate

    func animatedTransition(transition: AnimatedTransition,
         snapshotReferenceViewWhenReversed reversed: Bool) -> UIView
    {
        guard let indexPath = self.currentIndexPath else { return self.collectionView! }
        return self.collectionView!.guaranteedCellForItemAtIndexPath(indexPath)
    }

    func animatedTransition(transition: AnimatedTransition,
         willCreateSnapshotViewFromReferenceView reference: UIView)
    {
        guard let cell = reference as? CollectionViewTileCell else { return }
        cell.toggleAllBorders(true)
        cell.toggleContentAppearance(false)
    }

    func animatedTransition(transition: AnimatedTransition,
         didCreateSnapshotView snapshot: UIView, fromReferenceView reference: UIView)
    {
        guard let cell = reference as? CollectionViewTileCell else { return }
        cell.restoreOriginalBordersIfNeeded()
        cell.toggleContentAppearance(true)
    }

    func animatedTransition(transition: AnimatedTransition,
         willTransitionWithSnapshotReferenceView reference: UIView, reversed: Bool)
    {
        guard let cell = reference as? EventViewCell where transition is ZoomTransition else { return }
        // NOTE: Technically not needed, but we may not always be using a single-column layout.
        cell.alpha = 0.0
    }

    func animatedTransition(transition: AnimatedTransition,
         didTransitionWithSnapshotReferenceView reference: UIView, reversed: Bool)
    {
        guard let cell = reference as? EventViewCell where transition is ZoomTransition else { return }
        cell.alpha = 1.0
    }

    // MARK: TransitionInteractionDelegate

    func interactiveTransition(transition: InteractiveTransition,
         locationContextViewForGestureRecognizer recognizer: UIGestureRecognizer) -> UIView
    {
        return self.collectionView!
    }

    func interactiveTransition(transition: InteractiveTransition,
         snapshotReferenceViewAtLocation location: CGPoint, ofContextView contextView: UIView) -> UIView?
    {
        guard let indexPath = self.collectionView!.indexPathForItemAtPoint(location) else { return nil }
        return self.collectionView!.guaranteedCellForItemAtIndexPath(indexPath)
    }

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)
    {
        if let cell = referenceView as? EventViewCell,
               indexPath = self.collectionView!.indexPathForCell(cell)
        {
            self.currentIndexPath = indexPath
            self.performSegueWithIdentifier(Segue.EditEvent.rawValue, sender: transition)
        }
    }

    func beginInteractiveDismissalTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)
    {
        if let zoomTransitionTrait = self.navigationController?.transitioningDelegate as? CollectionViewZoomTransitionTrait {
            zoomTransitionTrait.isInteractive = true
            print("DEBUG")
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func interactiveTransition(transition: InteractiveTransition,
         destinationScaleForSnapshotReferenceView referenceView: UIView?,
         contextView: UIView, reversed: Bool) -> CGFloat
    {
        guard let referenceView = referenceView else { return -1.0 }
        return contextView.frame.height / (referenceView.frame.height * 2.0)
    }

}

// MARK: - Data

extension DayViewController {

    private func updateData() {
        self.events = (self.eventManager.monthsEvents?.eventsForDayOfDate(self.dayDate) ?? []) as! [Event]
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.events?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(EventViewCell), forIndexPath: indexPath)
        if let cell = cell as? EventViewCell {
            cell.setAccessibilityLabelsWithIndexPath(indexPath)

            if let event = self.events?[indexPath.item] {
                cell.eventText = event.title
                cell.detailsView.event = event
            }
        }
        return cell
    }

}

// MARK: - Event Cell

extension DayViewController {

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        self.currentIndexPath = indexPath
        return true
    }

    override func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.guaranteedCellForItemAtIndexPath(indexPath) as? CollectionViewTileCell else { return }
        cell.animateHighlighted()
    }

    override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.guaranteedCellForItemAtIndexPath(indexPath) as? CollectionViewTileCell else { return }
        cell.animateUnhighlighted()
    }

}

// MARK: - Layout

extension DayViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
         sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        var cellSizes = EventViewCellSizes(sizeClass: self.traitCollection.horizontalSizeClass)

        // NOTE: In case this screen ever needed multi-column support.
        var size = self.tileLayout.sizeForItemAtIndexPath(indexPath)
        size.height = cellSizes.emptyCellHeight

        if let event = self.events?[indexPath.item] {
            if event.startDate.hasCustomTime || event.hasLocation {
                size.height += cellSizes.detailsViewHeight
            }

            cellSizes.width = size.width
            let labelRect = EventViewCell.mainLabelTextRectForText(event.title, cellSizes: cellSizes)
            var labelHeight = floor(labelRect.size.height) // Avoid sub-pixel rendering.
            if labelHeight <= cellSizes.mainLabelMaxHeight && labelHeight > cellSizes.mainLabelLineHeight {
                labelHeight -= cellSizes.mainLabelLineHeight
            }
            let correctionRatio: CGFloat = 1.04 // Label height constants are rounded down for easier math.
            size.height += ceil(min(cellSizes.mainLabelMaxHeight, labelHeight) * correctionRatio)
        }

        return size
    }

}
