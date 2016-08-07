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
    private var currentSectionIndex: Int = 0
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
    private var previousContentOffset: CGPoint?

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
        setUpTitleView()
        // Traits.
        backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
        backgroundTapTrait.enabled = Appearance.minimalismEnabled
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
        guard let payload = notification.userInfo?.notificationUserInfoPayload() as? EntityUpdatedPayload,
            let events = events, collectionView = collectionView
            else { preconditionFailure("Bad notification, or no events.") }

        // Update associated state.
        if
            let event = payload.event,
            let nextIndexPath = events.indexPathForDayOfDate(event.startDate.dayDate)
            where nextIndexPath != currentIndexPath
        {
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
        guard
            let payload = notification.userInfo?.notificationUserInfoPayload() as? EntityAccessPayload,
            let result = payload.result where result == .Granted
            else { return }

        fetchEvents()
    }

}

// MARK: - Navigation

extension MonthsViewController {

    // MARK: Actions

    @IBAction private func unwindToMonths(sender: UIStoryboardSegue) {
        if
            let indexPath = currentIndexPath,
            let navigationController = presentedViewController as? NavigationViewController {
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
            guard
                let firstIndexPath = collectionView!.indexPathsForSelectedItems()?.first,
                let dayDate = events?.dayAtIndexPath(currentIndexPath ?? firstIndexPath)
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

enum ScrollDirection {
    case Top, Left, Bottom, Right
}

extension MonthsViewController: NavigationTitleScrollViewDataSource, NavigationTitleScrollViewDelegate
{

    private func setUpTitleView() {
        titleView.scrollViewDelegate = self
        titleView.dataSource = self
    }

    // NOTE: 'header*' refers to section header metrics, while 'title*' refers to navigation
    // bar title metrics. This function will not short unless we're at the edges.
    private func updateTitleViewContentOffsetToSectionHeader() {
        let currentIndex = currentSectionIndex

        // The three metrics for comparing against the title view.
        let titleHeight = titleView.frame.height
        var titleBottom = currentVisibleContentYOffset
        // NOTE: It turns out the spacing between the bar and title is about the same size as the
        // title item's top padding, so they cancel each other out (minus spacing, plus padding).
        var titleTop = titleBottom - titleHeight

        // We use this more than once, but also after conditional guards.
        func headerTopForIndexPath(indexPath: NSIndexPath) -> CGFloat? {
            // NOTE: This will get called a lot.
            guard
                let headerLayoutAttributes = tileLayout.layoutAttributesForSupplementaryViewOfKind(
                    UICollectionElementKindSectionHeader, atIndexPath: indexPath)
                else { return nil }

            // The top offset is that margin plus the main layout info's offset.
            let headerLabelTop = CGFloat(UIApplication.sharedApplication().statusBarHidden ? 0 : 9)
            return headerLayoutAttributes.frame.origin.y + headerLabelTop
        }

        var newIndex = currentIndex
        // When scrolling to top/bottom, if the header has visually gone past and below/above the
        // title, commit the switch to the previous/next title. If the header hasn't fully passed
        // the title, add the difference to the offset.
        var offsetChange: CGFloat = 0
        // The default title view content offset, for most of the time, is to offset to title for
        // current index.
        var offset: CGFloat = CGFloat(newIndex) * titleHeight

        switch currentScrollDirection {
        case .Top:
            let previousIndex = currentIndex - 1
            guard previousIndex >= 0 else { return }

            if let headerTop = headerTopForIndexPath(NSIndexPath(forItem: 0, inSection: currentIndex)) {
                // If passed, update new index first.
                if headerTop > titleBottom { newIndex = previousIndex }

                offsetChange = titleTop - headerTop
                offset = CGFloat(newIndex) * titleHeight

                // If passing.
                if headerTop >= titleTop && abs(offsetChange) <= titleHeight { offset += offsetChange }
            }
        case .Bottom:
            let nextIndex = currentIndex + 1
            guard nextIndex < collectionView!.numberOfSections() else { return }

            if let headerTop = headerTopForIndexPath(NSIndexPath(forItem: 0, inSection: nextIndex)) {
                // If passed, update new index first.
                if headerTop < titleTop { newIndex = nextIndex }

                offsetChange = titleBottom - headerTop
                offset = CGFloat(newIndex) * titleHeight

                // If passing.
                if headerTop <= titleBottom && abs(offsetChange) <= titleHeight { offset += offsetChange }
                //print("headerTop: \(headerTop), titleBottom: \(titleBottom), offset: \(offset)")
            }
        default:
            fatalError("Unsupported direction.")
        }

        titleView.setContentOffset(
            CGPoint(x: titleView.contentOffset.x, y: offset), animated: false
        )

        // Update state if needed.
        if newIndex != currentSectionIndex {
            //print(currentSectionIndex)
            currentSectionIndex = newIndex
            previousContentOffset = collectionView!.contentOffset
            titleView.updateVisibleItem()
        }
        //print("contentOffset: \(collectionView!.contentOffset.y)")
    }

    private var currentScrollDirection: ScrollDirection {
        if
            let previousContentOffset = previousContentOffset
            where collectionView!.contentOffset.y < previousContentOffset.y
        {
            return .Top
        }
        return .Bottom
    }

    private var currentVisibleContentYOffset: CGFloat {
        let scrollView = collectionView!
        var offset = scrollView.contentOffset.y
        //print(offset, tileLayout.viewportYOffset)
        if edgesForExtendedLayout.contains(.Top) {
            offset += tileLayout.viewportYOffset
        }
        return offset
    }

    // MARK: UIScrollViewDelegate

    override func scrollViewDidScroll(scrollView: UIScrollView) {
        guard events != nil else { return }
        updateTitleViewContentOffsetToSectionHeader()
    }

    // MARK: NavigationTitleScrollViewDataSource

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

    // MARK: NavigationTitleScrollViewDelegate

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
        if
            case kind = UICollectionElementKindSectionHeader,
            let headerView = view as? MonthHeaderView,
            let month = months?[indexPath.section] as? NSDate {
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
