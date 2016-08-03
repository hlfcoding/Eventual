//
//  DayViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class DayViewController: UICollectionViewController, CoordinatedViewController {

    // MARK: State

    weak var delegate: CoordinatedViewControllerDelegate!

    var currentIndexPath: NSIndexPath?

    // MARK: Add Event

    @IBOutlet private(set) var backgroundTapRecognizer: UITapGestureRecognizer!
    var backgroundTapTrait: CollectionViewBackgroundTapTrait!

    // MARK: Data Source

    var dayDate: NSDate!
    private var events: [Event]!
    private var eventManager: EventManager { return EventManager.defaultManager }

    // MARK: Layout

    private var tileLayout: CollectionViewTileLayout {
        return collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: Navigation

    private(set) var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: - Initializers

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUp()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    deinit {
        tearDown()
    }

    private func setUp() {
        customizeNavigationItem()

        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(
            self, selector: #selector(applicationDidBecomeActive(_:)),
            name: UIApplicationDidBecomeActiveNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(deleteEvent(_:)),
            name: EntityDeletionAction, object: nil
        )
        center.addObserver(
            self, selector: #selector(entityUpdateOperationDidComplete(_:)),
            name: EntityUpdateOperationNotification, object: nil
        )

        installsStandardGestureForInteractiveMovement = true
    }
    private func tearDown() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAccessibility(nil)
        // Data.
        updateData()
        // Title.
        title = NSDateFormatter.monthDayFormatter.stringFromDate(dayDate)
        customizeNavigationItem() // Hacky sync.
        // Layout customization.
        tileLayout.dynamicNumberOfColumns = false
        tileLayout.registerNib(UINib(nibName: String(EventDeletionDropzoneView), bundle: NSBundle.mainBundle()),
                                    forDecorationViewOfKind: CollectionViewTileLayout.deletionViewKind)
        // Traits.
        backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
        backgroundTapTrait.enabled = Appearance.minimalismEnabled
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        zoomTransitionTrait.isInteractionEnabled = true
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        backgroundTapTrait.updateOnAppearance(true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        backgroundTapTrait.updateOnAppearance(true, reverse: true)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if presentedViewController == nil {
            zoomTransitionTrait.isInteractionEnabled = false
        }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition(
            { context in self.tileLayout.invalidateLayout() },
            completion: nil
        )
    }

    // MARK: Handlers

    func applicationDidBecomeActive(notification: NSNotification) {
        // In case settings change.
        if let backgroundTapTrait = backgroundTapTrait {
            backgroundTapTrait.enabled = Appearance.minimalismEnabled
        }
    }

    func entityUpdateOperationDidComplete(notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard let _ = notification.userInfo?.notificationUserInfoPayload() as? EntityUpdatedPayload else { return }
        updateData()
        collectionView!.reloadData()
    }

    // MARK: - Actions

    @objc @IBAction private func deleteEvent(sender: AnyObject) {
        guard let indexPath = currentIndexPath, event = events?[indexPath.item]
            else { return }
        try! eventManager.removeEvent(event)
        currentIndexPath = nil // Reset.
    }

}

// MARK: - Navigation

extension DayViewController {

    // MARK: Actions

    @IBAction private func unwindToDay(sender: UIStoryboardSegue) {
        if
            let navigationController = presentedViewController as? NavigationViewController,
            let indexPath = currentIndexPath,
            let events = events
        {
            eventManager.updateEventsByMonthsAndDays() // FIXME
            updateData()
            collectionView!.reloadData()

            // Empty if moved to different day.
            var isCurrentEventInDay = !events.isEmpty
            if events.count > indexPath.item && events[indexPath.item].startDate.dayDate != dayDate {
                isCurrentEventInDay = false
            }
            if !isCurrentEventInDay {
                // Just do the default transition if the snapshotReferenceView is illegitimate.
                navigationController.transitioningDelegate = nil
                navigationController.modalPresentationStyle = .FullScreen
            }
        }
    }

    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        guard let rawIdentifier = segue.identifier, identifier = Segue(rawValue: rawIdentifier) else { return }
        switch identifier {

        case .AddEvent:
            currentIndexPath = nil // Reset.
            delegate.prepareAddEventSegue(segue)

        case .EditEvent:
            if sender is EventViewCell {
                zoomTransitionTrait.isInteractive = false
            }
            guard let indexPath = currentIndexPath, event = events?[indexPath.item] else { break }
            delegate.prepareEditEventSegue(segue, event: event)

        default: break
        }
    }

}

// MARK: CollectionViewBackgroundTapTraitDelegate

extension DayViewController: CollectionViewBackgroundTapTraitDelegate {

    func backgroundTapTraitDidToggleHighlight() {
        performSegueWithIdentifier(Segue.AddEvent.rawValue, sender: backgroundTapTrait)
    }

    func backgroundTapTraitFallbackBarButtonItem() -> UIBarButtonItem {
        let buttonItem = UIBarButtonItem(
            barButtonSystemItem: .Add,
            target: self, action: #selector(backgroundTapTraitDidToggleHighlight)
        )
        setUpAccessibility(buttonItem)
        return buttonItem
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension DayViewController: CollectionViewZoomTransitionTraitDelegate {

    func animatedTransition(transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView]
    {
        guard let cell = cell as? EventViewCell else { preconditionFailure("Wrong cell.") }
        return [cell.mainLabel, cell.detailsView]
    }

    func animatedTransition(transition: AnimatedTransition,
                            subviewInDestinationViewController viewController: UIViewController,
                            forSubview subview: UIView) -> UIView?
    {
        guard let viewController = viewController as? EventViewController else { preconditionFailure("Wrong view controller.") }
        switch subview {
        case is UILabel: return viewController.descriptionView.superview
        case is EventDetailsView: return viewController.detailsView
        default: fatalError("Unsupported source subview.")
        }
    }

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
                                                withSnapshotReferenceCell cell: CollectionViewTileCell)
    {
        performSegueWithIdentifier(Segue.EditEvent.rawValue, sender: transition)
    }

}

// MARK: - Data

extension DayViewController {

    private func updateData() {
        events = (eventManager.monthsEvents?.eventsForDayOfDate(dayDate) ?? []) as! [Event]
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return events?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(EventViewCell), forIndexPath: indexPath)
        if let cell = cell as? EventViewCell {
            cell.setUpAccessibilityWithIndexPath(indexPath)

            if let event = events?[indexPath.item] {
                EventViewCell.renderCell(cell, fromEvent: event)
            }
        }
        return cell
    }

    override func collectionView(collectionView: UICollectionView,
                                 canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        guard let event = events?[indexPath.item] where event.calendar.allowsContentModifications
            else { return false }
        tileLayout.indexPathToDelete = indexPath
        currentIndexPath = indexPath
        return true
    }
    override func collectionView(collectionView: UICollectionView,
                                 moveItemAtIndexPath sourceIndexPath: NSIndexPath,
                                 toIndexPath destinationIndexPath: NSIndexPath)
    {
        collectionView.reloadData() // Cancel.
        currentIndexPath = nil // Reset.
    }
}

// MARK: - Event Cell

extension DayViewController {

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard let event = events?[indexPath.item] where event.calendar.allowsContentModifications
            else { return false }
        currentIndexPath = indexPath
        return true
    }

    override func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? CollectionViewTileCell
            where indexPath == currentIndexPath
            else { return }
        cell.animateHighlighted(
            depressDepth: UIOffset(horizontal: 0, vertical: 2 / cell.frame.height)
        )
    }

    override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? CollectionViewTileCell else { return }
        cell.animateUnhighlighted()
    }

}

// MARK: - Layout

extension DayViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        var cellSizes = EventViewCellSizes(sizeClass: traitCollection.horizontalSizeClass)

        // NOTE: In case this screen ever needed multi-column support.
        var size = tileLayout.sizeForItemAtIndexPath(indexPath)
        size.height = cellSizes.emptyCellHeight

        if let event = events?[indexPath.item] {
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
