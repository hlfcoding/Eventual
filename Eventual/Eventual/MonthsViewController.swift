//
//  MonthsViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class MonthsViewController: UICollectionViewController, CoordinatedViewController {

    // MARK: State

    weak var delegate: CoordinatedViewControllerDelegate!

    var currentIndexPath: NSIndexPath?

    private var currentDate: NSDate = NSDate()
    private var currentSelectedDayDate: NSDate?

    /**
     This flag guards `fetchEvents` calls, which can happen in multiple places and possibly at once.
     */
    private var isFetching = false

    // MARK: Add Event

    @IBOutlet private(set) var backgroundTapRecognizer: UITapGestureRecognizer!
    private var backgroundTapTrait: CollectionViewBackgroundTapTrait!

    // MARK: Data Source

    private var events: MonthsEvents? { return eventManager.monthsEvents }
    private var eventManager: EventManager { return EventManager.defaultManager }

    private var months: NSArray? { return events?.months }

    // MARK: Layout

    private var tileLayout: CollectionViewTileLayout {
        return collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: Navigation

    private(set) var zoomTransitionTrait: CollectionViewZoomTransitionTrait!
    @IBOutlet private(set) var backToTopTapRecognizer: UITapGestureRecognizer!

    // MARK: Title View

    @IBOutlet private(set) var titleView: NavigationTitleScrollView!
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
            self, selector: #selector(entityUpdateOperationDidComplete(_:)),
            name: EntityUpdateOperationNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(eventAccessRequestDidComplete(_:)),
            name: EntityAccessNotification, object: nil
        )
    }
    private func tearDown() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAccessibility(nil)
        // Title.
        titleView.scrollViewDelegate = self
        titleView.dataSource = self
        // Traits.
        backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
        backgroundTapTrait.enabled = Appearance.minimalismEnabled
        titleScrollSyncTrait = CollectionViewTitleScrollSyncTrait(delegate: self)
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
        // Load.
        fetchEvents()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        zoomTransitionTrait.isInteractionEnabled = true
        // In case new sections have been added from new events.
        titleView.refreshSubviews()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        backgroundTapTrait.updateOnAppearance(true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if presentedViewController == nil {
            zoomTransitionTrait.isInteractionEnabled = false
        }
    }

    // MARK: Handlers

    func applicationDidBecomeActive(notification: NSNotification) {
        fetchEvents()
        // In case settings change.
        if let backgroundTapTrait = backgroundTapTrait {
            backgroundTapTrait.enabled = Appearance.minimalismEnabled
        }
    }

    func didFetchEvents() {
        collectionView!.reloadData()

        // In case new sections have been added from new events.
        titleView.refreshSubviews()
    }

    func entityUpdateOperationDidComplete(notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard let
            payload = notification.userInfo?.notificationUserInfoPayload() as? EntityUpdatedPayload,
            events = events, collectionView = collectionView
            else { preconditionFailure("Bad notification, or no events.") }

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
            collectionView.deleteItemsAtIndexPaths(updatingInfo.deletions);
            collectionView.insertSections(updatingInfo.sectionInsertions)
            collectionView.insertItemsAtIndexPaths(updatingInfo.insertions);
            collectionView.reloadItemsAtIndexPaths(updatingInfo.reloads);

        }) { finished in
            guard finished &&
                (updatingInfo.sectionDeletions.count > 0 || updatingInfo.sectionInsertions.count > 0)
                else { return }

            self.titleView.refreshSubviews()
        }
    }

    func eventAccessRequestDidComplete(notification: NSNotification) {
        guard let
            payload = notification.userInfo?.notificationUserInfoPayload() as? EntityAccessPayload,
            result = payload.result where result == .Granted
            else { return }

        fetchEvents()
    }

}

// MARK: - Navigation

extension MonthsViewController {

    // MARK: Actions

    @IBAction private func unwindToMonths(sender: UIStoryboardSegue) {
        if let
            indexPath = currentIndexPath,
            navigationController = presentedViewController as? NavigationViewController {
            let isDayRemoved = events?.dayAtIndexPath(indexPath) != currentSelectedDayDate
            // Just do the default transition if the snapshotReferenceView is illegitimate.
            if isDayRemoved {
                navigationController.transitioningDelegate = nil
                navigationController.modalPresentationStyle = .FullScreen
            }
        }
    }

    @IBAction private func returnBackToTop(sender: UITapGestureRecognizer) {
        collectionView!.setContentOffset(
            CGPoint(x: 0, y: -collectionView!.contentInset.top),
            animated: true
        )
    }

    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        super.prepareForSegue(segue, sender: sender)

        guard let rawIdentifier = segue.identifier, identifier = Segue(rawValue: rawIdentifier) else { return }
        switch identifier {

        case .ShowDay:
            guard let
                firstIndexPath = collectionView!.indexPathsForSelectedItems()?.first,
                dayDate = events?.dayAtIndexPath(currentIndexPath ?? firstIndexPath)
                else { break }

            if sender is DayViewCell {
                zoomTransitionTrait.isInteractive = false
            }
            currentSelectedDayDate = dayDate
            delegate.prepareShowDaySegue(segue, dayDate: dayDate)

        case .AddEvent:
            currentIndexPath = nil // Reset.
            delegate.prepareAddEventSegue(segue)

        default: assertionFailure("Unsupported segue \(identifier).")
        }
    }

}

// MARK: CollectionViewBackgroundTapTraitDelegate

extension MonthsViewController: CollectionViewBackgroundTapTraitDelegate {

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

extension MonthsViewController: CollectionViewZoomTransitionTraitDelegate {

    func animatedTransition(transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView] {
        return [cell.innerContentView]
    }

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
                                                withSnapshotReferenceCell cell: CollectionViewTileCell) {
        performSegueWithIdentifier(Segue.ShowDay.rawValue, sender: transition)
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
        var titleText: String?
        var label: UILabel?
        let month = events?.monthAtIndex(index)
        if let month = month {
            titleText = MonthHeaderView.formattedTextForText(NSDateFormatter.monthFormatter.stringFromDate(month))
        }
        if let info = NSBundle.mainBundle().infoDictionary {
            // Default to app title.
            titleText = titleText ?? (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String)
        }
        if let text = titleText {
            label = titleView.newItemOfType(.Label, withText: MonthHeaderView.formattedTextForText(text)) as? UILabel
            if let _ = month {
                label?.accessibilityLabel = text as String
            }
        }
        if index == 0 {
            renderAccessibilityValueForElement(titleView, value: label)
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

    private func fetchEvents() {
        guard !isFetching else { return }
        isFetching = true

        let componentsToAdd = NSDateComponents(); componentsToAdd.year = 1
        let endDate = NSCalendar.currentCalendar().dateByAddingComponents(
            componentsToAdd, toDate: currentDate, options: []
            )!

        do {
            try eventManager.fetchEventsFromDate(untilDate: endDate) {
                self.didFetchEvents()
                self.isFetching = false
            }
        } catch { isFetching = false }
    }

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
