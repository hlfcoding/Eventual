//
//  DayViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class DayViewController: UICollectionViewController, DayScreen {

    // MARK: DayScreen

    weak var coordinator: NavigationCoordinatorProtocol?

    var currentIndexPath: NSIndexPath?
    var currentSelectedEvent: Event?
    var dayDate: NSDate!

    var isCurrentItemRemoved: Bool {
        guard
            let indexPath = currentIndexPath, event = currentSelectedEvent, events = events
            where events.count > indexPath.item
            else { return true }

        return event.startDate.dayDate != dayDate
    }

    var selectedEvent: Event? {
        guard
            let indexPath = currentIndexPath, events = events
            where events.count > indexPath.item
            else { return nil }

        return events[indexPath.item]
    }

    var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: Data Source

    private var events: [Event]!

    // MARK: Interaction

    @IBOutlet private(set) var backgroundTapRecognizer: UITapGestureRecognizer!
    var backgroundTapTrait: CollectionViewBackgroundTapTrait!

    var deletionTrait: CollectionViewDragDropDeletionTrait!
    
    // MARK: Layout

    private var tileLayout: CollectionViewTileLayout {
        return collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: - Initializers

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    private func setUp() {
        customizeNavigationItem()

        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(
            self, selector: #selector(applicationDidBecomeActive(_:)),
            name: UIApplicationDidBecomeActiveNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(entityUpdateOperationDidComplete(_:)),
            name: EntityUpdateOperationNotification, object: nil
        )
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAccessibility(nil)
        // Data.
        updateData(andReload: false)
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
        deletionTrait = CollectionViewDragDropDeletionTrait(delegate: self)
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
            completion: { context in self.backgroundTapTrait.updateFallbackHitArea() }
        )
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        coordinator?.prepareForSegue(segue, sender: sender)
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
        guard let payload = notification.userInfo?.notificationUserInfoPayload() as? EntityUpdatedPayload else { return }
        if let event = payload.event {
            let previousEvent = payload.presave.event
            if event.startDate.dayDate.isEqualToDate(dayDate) {
                let didChangeOrder = !event.startDate.isEqualToDate(previousEvent.startDate)
                if didChangeOrder, let
                    events = coordinator?.monthsEvents?.eventsForDayOfDate(dayDate) as? [Event],
                    index = events.indexOf(event) {
                    currentIndexPath = NSIndexPath(forItem: index, inSection: 0)
                }
            } else {
                currentIndexPath = nil
            }
        }

        updateData(andReload: true)
    }

    // MARK: Actions

    @IBAction private func prepareForUnwindSegue(sender: UIStoryboardSegue) {
        coordinator?.prepareForSegue(sender, sender: nil)
    }

    // MARK: Data

    private func updateData(andReload reload: Bool) {
        events = (coordinator?.monthsEvents?.eventsForDayOfDate(dayDate) ?? []) as! [Event]
        if reload {
            collectionView!.reloadData()
        }
    }

}

// MARK: CollectionViewBackgroundTapTraitDelegate

extension DayViewController: CollectionViewBackgroundTapTraitDelegate {

    var backgroundFallbackHitAreaHeight: CGFloat { return tileLayout.viewportYOffset }

    func backgroundTapTraitDidToggleHighlight() {
        coordinator?.performNavigationActionForTrigger(.BackgroundTap, viewController: self)
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

// MARK: CollectionViewDragDropDeletionTraitDelegate

extension DayViewController: CollectionViewDragDropDeletionTraitDelegate {

    func canDeleteCellOnDrop(cellFrame: CGRect) -> Bool {
        return tileLayout.deletionDropZoneAttributes?.frame.intersects(cellFrame) ?? false
    }

    func canDragCell(cellIndexPath: NSIndexPath) -> Bool {
        guard cellIndexPath.row < events.count else { return false }
        return events[cellIndexPath.row].calendar.allowsContentModifications
    }

    func deleteDroppedCell(cell: UIView, completion: () -> Void) throws {
        guard let
            coordinator = coordinator, indexPath = currentIndexPath,
            event = events?[indexPath.item]
            else { preconditionFailure() }
        try coordinator.removeEvent(event)
        currentIndexPath = nil
        completion()
    }

    func finalFrameForDroppedCell() -> CGRect {
        guard let dropZoneAttributes = tileLayout.deletionDropZoneAttributes else { preconditionFailure() }
        return CGRect(origin: dropZoneAttributes.center, size: CGSizeZero)
    }

    func maxYForDraggingCell() -> CGFloat {
        guard let collectionView = collectionView else { preconditionFailure() }
        return (collectionView.bounds.height + collectionView.contentOffset.y
            - tileLayout.deletionDropZoneHeight + CollectionViewTileCell.borderSize)
    }

    func minYForDraggingCell() -> CGFloat {
        guard let collectionView = collectionView else { preconditionFailure() }
        return collectionView.bounds.minY + tileLayout.viewportYOffset
    }

    func didCancelDraggingCellForDeletion(cellIndexPath: NSIndexPath) {
        currentIndexPath = nil
        tileLayout.deletionDropZoneHidden = true
    }

    func didRemoveDroppedCellAfterDeletion(cellIndexPath: NSIndexPath) {
        tileLayout.deletionDropZoneHidden = true
    }

    func willStartDraggingCellForDeletion(cellIndexPath: NSIndexPath) {
        currentIndexPath = cellIndexPath
        tileLayout.deletionDropZoneHidden = false
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension DayViewController: CollectionViewZoomTransitionTraitDelegate {

    func animatedTransition(transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView] {
        guard let cell = cell as? EventViewCell else { preconditionFailure("Wrong cell.") }
        return [cell.mainLabel, cell.detailsView]
    }

    func animatedTransition(transition: AnimatedTransition,
                            subviewInDestinationViewController viewController: UIViewController,
                            forSubview subview: UIView) -> UIView? {
        guard let viewController = viewController as? EventViewController else { preconditionFailure("Wrong view controller.") }
        switch subview {
        case is UILabel: return viewController.descriptionView.superview
        case is EventDetailsView: return viewController.detailsView
        default: fatalError("Unsupported source subview.")
        }
    }

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
                                                withSnapshotReferenceCell cell: CollectionViewTileCell) {
        coordinator?.performNavigationActionForTrigger(.InteractiveTransitionBegin, viewController: self)
    }

}

// MARK: - Data

extension DayViewController {

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

}

// MARK: - Event Cell

extension DayViewController {

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
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
                        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let cellSizes = EventViewCellSizes(sizeClass: traitCollection.horizontalSizeClass)

        // NOTE: In case this screen ever needed multi-column support.
        var size = tileLayout.sizeForItemAtIndexPath(indexPath)
        size.height = cellSizes.emptyCellHeight

        if let event = events?[indexPath.item] {
            if event.startDate.hasCustomTime || event.hasLocation {
                size.height += cellSizes.detailsViewHeight
            }

            size.height += cellSizes.mainLabelLineHeight
        }

        return size
    }

}
