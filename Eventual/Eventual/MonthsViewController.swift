//
//  MonthsViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class MonthsViewController: UICollectionViewController, MonthsScreen {

    // MARK: CoordinatedViewController

    weak var coordinator: NavigationCoordinatorProtocol?

    // MARK: MonthsScreen

    var currentIndexPath: NSIndexPath?
    var currentSelectedDayDate: NSDate?

    var isCurrentItemRemoved: Bool {
        guard let indexPath = currentIndexPath else { return false }
        return events?.dayAtIndexPath(indexPath) != currentSelectedDayDate
    }

    var selectedDayDate: NSDate? {
        guard let indexPath = currentIndexPath ?? collectionView!.indexPathsForSelectedItems()?.first
            else { return nil }
        return events?.dayAtIndexPath(indexPath)
    }

    var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: Data Source

    private var events: MonthsEvents? { return coordinator?.monthsEvents }
    private var months: NSArray? { return events?.months }

    // MARK: Interaction

    @IBOutlet private(set) var backgroundTapRecognizer: UITapGestureRecognizer!
    private var backgroundTapTrait: CollectionViewBackgroundTapTrait!

    @IBOutlet private(set) var backToTopTapRecognizer: UITapGestureRecognizer!

    var deletionTrait: CollectionViewDragDropDeletionTrait!

    // MARK: Layout

    private var tileLayout: CollectionViewTileLayout {
        return collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: Title View

    @IBOutlet private(set) var titleView: NavigationTitleMaskedScrollView!
    private var titleScrollSyncTrait: CollectionViewTitleScrollSyncTrait!

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
            self, selector: #selector(entityFetchOperationDidComplete(_:)),
            name: EntityFetchOperationNotification, object: nil
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
        // Title.
        titleView.delegate = self
        titleView.dataSource = self
        // Layout customization.
        tileLayout.registerNib(UINib(nibName: String(EventDeletionDropzoneView), bundle: NSBundle.mainBundle()),
                               forDecorationViewOfKind: CollectionViewTileLayout.deletionViewKind)
        // Traits.
        backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
        backgroundTapTrait.enabled = Appearance.minimalismEnabled
        deletionTrait = CollectionViewDragDropDeletionTrait(delegate: self)
        titleScrollSyncTrait = CollectionViewTitleScrollSyncTrait(delegate: self)
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // In case new sections have been added from new events.
        titleView.refreshSubviews()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        backgroundTapTrait.updateOnAppearance(true)
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition(
            { context in self.tileLayout.invalidateLayout() },
            completion: nil
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

    func entityFetchOperationDidComplete(notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard
            let payload = notification.userInfo?.notificationUserInfoPayload() as? EntitiesFetchedPayload,
            case payload.fetchType = EntitiesFetched.UpcomingEvents
            else { return }

        collectionView!.reloadData()

        // In case new sections have been added from new events.
        titleView.refreshSubviews()
    }

    func entityUpdateOperationDidComplete(notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard let
            payload = notification.userInfo?.notificationUserInfoPayload() as? EntityUpdatedPayload,
            events = events, collectionView = collectionView
            else { return }

        // Update associated state.
        if let
            event = payload.event,
            nextIndexPath = events.indexPathForDayOfDate(event.startDate.dayDate)
            where nextIndexPath != currentIndexPath {
            currentIndexPath = nextIndexPath
        }

        let updatingInfo = events.indexPathUpdatesForEvent(
            (event: payload.event, currentIndexPath: payload.presave.toIndexPath),
            oldEventInfo: (event: payload.presave.event, currentIndexPath: payload.presave.fromIndexPath)
        )

        collectionView.performBatchUpdates({
            collectionView.deleteSections(updatingInfo.sectionDeletions)
            collectionView.deleteItemsAtIndexPaths(updatingInfo.deletions)
            collectionView.insertSections(updatingInfo.sectionInsertions)
            collectionView.insertItemsAtIndexPaths(updatingInfo.insertions)
            collectionView.reloadItemsAtIndexPaths(updatingInfo.reloads)

        }) { finished in
            guard finished &&
                (updatingInfo.sectionDeletions.count > 0 || updatingInfo.sectionInsertions.count > 0)
                else { return }

            self.titleView.refreshSubviews()
        }
    }

    // MARK: - Actions

    @IBAction private func prepareForUnwindSegue(sender: UIStoryboardSegue) {
        coordinator?.prepareForSegue(sender, sender: nil)
    }

    @IBAction private func returnBackToTop(sender: UITapGestureRecognizer) {
        collectionView!.setContentOffset(
            CGPoint(x: 0, y: -collectionView!.contentInset.top),
            animated: true
        )
    }
    
}

// MARK: CollectionViewBackgroundTapTraitDelegate

extension MonthsViewController: CollectionViewBackgroundTapTraitDelegate {

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

extension MonthsViewController: CollectionViewDragDropDeletionTraitDelegate {

    func canDeleteCellOnDrop(cellFrame: CGRect) -> Bool {
        return tileLayout.deletionDropZoneAttributes?.frame.intersects(cellFrame) ?? false
    }

    func canDragCell(cellIndexPath: NSIndexPath) -> Bool {
        guard let dayEvents =  events?.eventsForDayAtIndexPath(cellIndexPath) as? [Event] else { return false }
        return dayEvents.reduce(true) { return $0 && $1.calendar.allowsContentModifications }
    }

    func deleteDroppedCell(cell: UIView, completion: () -> Void) throws {
        guard let coordinator = coordinator, indexPath = currentIndexPath,
            dayEvents = events?.eventsForDayAtIndexPath(indexPath) as? [Event]
            else { preconditionFailure() }
        try coordinator.removeDayEvents(dayEvents)
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
        guard let collectionView = collectionView else { preconditionFailure() }
        currentIndexPath = nil
        let shouldDeleteSection = collectionView.numberOfItemsInSection(cellIndexPath.section) == 1
        collectionView.performBatchUpdates({
            if shouldDeleteSection {
                collectionView.deleteSections(NSIndexSet(index: cellIndexPath.section))
            }
            collectionView.deleteItemsAtIndexPaths([cellIndexPath])
        }) { finished in
            if finished && shouldDeleteSection {
                self.titleView.refreshSubviews()
            }
        }
        tileLayout.deletionDropZoneHidden = true
    }

    func willStartDraggingCellForDeletion(cellIndexPath: NSIndexPath) {
        currentIndexPath = cellIndexPath
        tileLayout.deletionDropZoneHidden = false
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension MonthsViewController: CollectionViewZoomTransitionTraitDelegate {

    func animatedTransition(transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView] {
        return [cell.innerContentView]
    }

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
                                                withSnapshotReferenceCell cell: CollectionViewTileCell) {
        coordinator?.performNavigationActionForTrigger(.InteractiveTransitionBegin, viewController: self)
    }

}

// MARK: - Title View

extension MonthsViewController: CollectionViewTitleScrollSyncTraitDelegate {

    var currentVisibleContentYOffset: CGFloat {
        let scrollView = collectionView!
        var offset = scrollView.contentOffset.y
        //print(offset, tileLayout.viewportYOffset)
        if edgesForExtendedLayout.contains(.Top) {
            offset += tileLayout.viewportYOffset
        }
        return offset
    }

    func titleScrollSyncTraitLayoutAttributesAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return tileLayout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader,
                                                                     atIndexPath: indexPath)
    }

    // MARK: UIScrollViewDelegate

    override func scrollViewDidScroll(scrollView: UIScrollView) {
        guard events != nil else { return }
        titleScrollSyncTrait.syncTitleViewContentOffsetsWithSectionHeader()
    }

}

// MARK: NavigationTitleScrollViewDataSource

extension MonthsViewController: NavigationTitleScrollViewDataSource {

    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int {
        guard let months = months where months.count > 0 else { return 1 }
        return numberOfSectionsInCollectionView(collectionView!)
    }

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView? {
        guard scrollView == titleView.scrollView else { return nil }
        guard let month = events?.monthAtIndex(index) else {
            guard let
                info = NSBundle.mainBundle().infoDictionary,
                text = (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String)
                else { return nil }
            // Default to app title.
            return scrollView.newItemOfType(.Label, withText: text)
        }
        let text = MonthHeaderView.formattedTextForText(NSDateFormatter.monthFormatter.stringFromDate(month))
        let label = scrollView.newItemOfType(.Label, withText: MonthHeaderView.formattedTextForText(text))
        if index == 0 {
            renderAccessibilityValueForElement(scrollView, value: label)
        }
        return label
    }

}

// MARK: NavigationTitleScrollViewDelegate

extension MonthsViewController: NavigationTitleScrollViewDelegate {

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, didChangeVisibleItem visibleItem: UIView) {
        renderAccessibilityValueForElement(scrollView, value: visibleItem)
    }

}

// MARK: - Data

extension MonthsViewController {

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return events?.daysForMonthAtIndex(section)?.count ?? 0
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return months?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView,
                                 cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(DayViewCell), forIndexPath: indexPath)
        if let
            cell = cell as? DayViewCell,
            dayDate = events?.dayAtIndexPath(indexPath),
            dayEvents = events?.eventsForDayAtIndexPath(indexPath) {
            DayViewCell.renderCell(cell, fromDayEvents: dayEvents, dayDate: dayDate)
            cell.setUpAccessibilityWithIndexPath(indexPath)
        }
        return cell
    }

    override func collectionView(collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryViewOfKind(
            kind, withReuseIdentifier: String(MonthHeaderView), forIndexPath: indexPath
        )
        if case
            kind = UICollectionElementKindSectionHeader,
            let headerView = view as? MonthHeaderView,
            month = months?[indexPath.section] as? NSDate {
            headerView.monthName = NSDateFormatter.monthFormatter.stringFromDate(month)
            headerView.monthLabel.textColor = Appearance.lightGrayTextColor
        }
        return view
    }

}

// MARK: - Day Cell

extension MonthsViewController {

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView,
                                 shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        currentIndexPath = indexPath
        return true
    }

    override func collectionView(collectionView: UICollectionView,
                                 didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? CollectionViewTileCell else { return }
        cell.animateHighlighted()
    }

    override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? CollectionViewTileCell else { return }
        cell.animateUnhighlighted()
    }

}

// MARK: - Layout

extension MonthsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section > 0 else { return CGSize(width: 0.01, height: 0.01) } // Still add, but hide.
        return (collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize ?? CGSizeZero
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return tileLayout.sizeForItemAtIndexPath(indexPath)
    }

}
