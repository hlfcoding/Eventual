//
//  MonthsViewController.swift
//  Eventual
//
//  Created by Peng Wang on 6/2/14.
//  Copyright (c) 2014-2016 Eventual App. All rights reserved.
//

import UIKit
import EventKit

class MonthsViewController: UICollectionViewController, CoordinatedViewController {

    // MARK: State

    weak var delegate: ViewControllerDelegate!

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
    var backgroundTapTrait: CollectionViewBackgroundTapTrait!

    // MARK: Data Source

    private var events: MonthsEvents? { return self.eventManager.monthsEvents }
    private var eventManager: EventManager { return EventManager.defaultManager }

    private var months: NSArray? { return self.events?.months }

    // MARK: Layout

    private var tileLayout: CollectionViewTileLayout {
        return self.collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: Navigation

    private(set) var zoomTransitionTrait: CollectionViewZoomTransitionTrait!
    @IBOutlet var backToTopTapRecognizer: UITapGestureRecognizer!

    // MARK: Title View

    @IBOutlet private var titleView: NavigationTitleScrollView!
    private var previousContentOffset: CGPoint?

    // MARK: Appearance
    private var appearanceManager: AppearanceManager { return AppearanceManager.defaultManager }

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
            selector: Selector("applicationDidBecomeActive:"),
            name: UIApplicationDidBecomeActiveNotification, object: nil
        )
        center.addObserver( self,
            selector: Selector("entitySaveOperationDidComplete:"),
            name: EntitySaveOperationNotification, object: nil
        )
        center.addObserver( self,
            selector: Selector("eventAccessRequestDidComplete:"),
            name: EntityAccessNotification, object: nil
        )
    }
    private func tearDown() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAccessibilityLabels()
        // Title.
        self.setUpTitleView()
        // Transition.
        self.zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
        // Traits.
        self.backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
        // Load.
        self.fetchEvents()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.zoomTransitionTrait.isInteractionEnabled = true

        // In case new sections have been added from new events.
        self.titleView.refreshSubviews()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.backgroundTapTrait.updateOnAppearance(true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // TODO: Doesn't quite work yet.
        //self.backgroundTapTrait.updateOnAppearance(true, reverse: true)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.presentedViewController == nil {
            self.zoomTransitionTrait.isInteractionEnabled = false
        }
    }

    private func setAccessibilityLabels() {
        self.collectionView!.accessibilityLabel = t(Label.MonthDays.rawValue)
    }

    // MARK: Handlers

    func applicationDidBecomeActive(notification: NSNotification) {
        self.fetchEvents()
    }

    func didFetchEvents() {
        self.collectionView!.reloadData()

        // In case new sections have been added from new events.
        self.titleView.refreshSubviews()
    }

    func entitySaveOperationDidComplete(notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard (notification.userInfo?[TypeKey] as? UInt) == EKEntityType.Event.rawValue else { return }
        guard let data = notification.userInfo?[DataKey], event = data["event"] as? Event else { return }

        let presaveEventSnapshot = data["presaveEventSnapshot"] as? Event
        let presaveFromIndexPath = data["presaveFromIndexPath"] as? NSIndexPath
        let presaveToIndexPath = data["presaveToIndexPath"] as? NSIndexPath

        let dayDate = event.startDate.dayDate
        let dayEvents = self.events?.eventsForDayOfDate(dayDate)
        let toIndexPath = self.events?.indexPathForDayOfDate(dayDate)

        var indexPathsToDelete = [NSIndexPath]()
        var indexPathsToInsert = [NSIndexPath]()
        var indexPathsToReload = [NSIndexPath]()

        // If is a move:
        if let presaveFromIndexPath = presaveFromIndexPath, toIndexPath = toIndexPath,
               fromStartDate = presaveEventSnapshot?.startDate.dayDate where fromStartDate != dayDate
        {
            // Update source cell given positions based on old events state.
            if self.events?.indexPathForDayOfDate(fromStartDate) == nil { // Was only event for source cell.
                indexPathsToDelete.append(presaveFromIndexPath)
            } else {
                indexPathsToReload.append(presaveFromIndexPath)
            }
            // Update destination cell given positions based on old events state.
            if dayEvents?.count == 1 { // Is only event for destination cell.
                indexPathsToInsert.append(toIndexPath)
            } else if let presaveToIndexPath = presaveToIndexPath {
                indexPathsToReload.append(presaveToIndexPath)
            }
        // If is an addition:
        } else if presaveEventSnapshot == nil, let toIndexPath = toIndexPath {
            // Update destination cell.
            if dayEvents?.count == 1 { // Is only event for destination cell.
                indexPathsToInsert.append(toIndexPath)
            } else {
                indexPathsToReload.append(toIndexPath)
            }
        }

        self.collectionView?.performBatchUpdates({
            self.collectionView?.deleteItemsAtIndexPaths(indexPathsToDelete);
            self.collectionView?.insertItemsAtIndexPaths(indexPathsToInsert);
            self.collectionView?.reloadItemsAtIndexPaths(indexPathsToReload);
        }, completion: nil)
    }

    func eventAccessRequestDidComplete(notification: NSNotification) {
        guard let result = (notification.userInfo as? [String: AnyObject])?[ResultKey] as? String
              where result == EntityAccessGranted
              else { return }
        self.fetchEvents()
    }

}

// MARK: - Navigation

extension MonthsViewController: CollectionViewBackgroundTapTraitDelegate,
                                CollectionViewZoomTransitionTraitDelegate
{

    // MARK: Actions

    @IBAction private func unwindToMonths(sender: UIStoryboardSegue) {
        if let indexPath = self.currentIndexPath,
               navigationController = self.presentedViewController as? NavigationViewController
        {
            let isDayRemoved = self.events?.dayAtIndexPath(indexPath) != self.currentSelectedDayDate
            // Just do the default transition if the snapshotReferenceView is illegitimate.
            if isDayRemoved {
                navigationController.transitioningDelegate = nil
                navigationController.modalPresentationStyle = .FullScreen
            }
        }
    }

    @IBAction private func returnBackToTop(sender: UITapGestureRecognizer) {
        self.collectionView!.setContentOffset(
            CGPoint(x: 0.0, y: -self.collectionView!.contentInset.top),
            animated: true
        )
    }

    // MARK: CollectionViewBackgroundTapTraitDelegate

    func backgroundTapTraitDidToggleHighlight() {
        self.performSegueWithIdentifier(Segue.AddEvent.rawValue, sender: self.backgroundTapTrait)
    }


    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        super.prepareForSegue(segue, sender: sender)

        guard let rawIdentifier = segue.identifier, identifier = Segue(rawValue: rawIdentifier) else { return }
        switch identifier {

        case .ShowDay:
            guard let firstIndexPath = self.collectionView?.indexPathsForSelectedItems()?.first,
                      dayDate = self.events?.dayAtIndexPath(self.currentIndexPath ?? firstIndexPath)
                  else { break }
            if sender is DayViewCell {
                self.zoomTransitionTrait.isInteractive = false
            }
            self.currentSelectedDayDate = dayDate
            self.delegate.prepareShowDaySegue(segue, dayDate: dayDate)

        case .AddEvent:
            self.currentIndexPath = nil // Reset.
            self.delegate.prepareAddEventSegue(segue)

        default: assertionFailure("Unsupported segue \(identifier).")
        }
    }

    // MARK: CollectionViewZoomTransitionTraitDelegate

    func animatedTransition(transition: AnimatedTransition,
         subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView]
    {
        return [cell.innerContentView]
    }

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
         withSnapshotReferenceCell cell: CollectionViewTileCell)
    {
        self.performSegueWithIdentifier(Segue.ShowDay.rawValue, sender: transition)
    }

}

// MARK: - Title View

enum ScrollDirection {
    case Top, Left, Bottom, Right
}

extension MonthsViewController: NavigationTitleScrollViewDataSource, NavigationTitleScrollViewDelegate
{

    private func setUpTitleView() {
        self.titleView.delegate = self
        self.titleView.dataSource = self
    }

    // NOTE: 'header*' refers to section header metrics, while 'title*' refers to navigation
    // bar title metrics. This function will not short unless we're at the edges.
    private func updateTitleViewContentOffsetToSectionHeader() {
        let currentIndex = self.currentSectionIndex

        // The three metrics for comparing against the title view.
        let titleHeight = self.titleView.frame.height
        var titleBottom = self.currentVisibleContentYOffset
        // NOTE: It turns out the spacing between the bar and title is about the same size as the
        // title item's top padding, so they cancel each other out (minus spacing, plus padding).
        var titleTop = titleBottom - titleHeight

        // We use this more than once, but also after conditional guards.
        func headerTopForIndexPath(indexPath: NSIndexPath) -> CGFloat? {
            // NOTE: This will get called a lot.
            guard let headerLayoutAttributes = self.tileLayout.layoutAttributesForSupplementaryViewOfKind(
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
        var offsetChange: CGFloat = 0.0
        // The default title view content offset, for most of the time, is to offset to title for
        // current index.
        var offset: CGFloat = CGFloat(newIndex) * titleHeight

        switch self.currentScrollDirection {
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
            guard nextIndex < self.collectionView!.numberOfSections() else { return }

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

        self.titleView.setContentOffset(
            CGPoint(x: self.titleView.contentOffset.x, y: offset), animated: false
        )

        // Update state if needed.
        if newIndex != self.currentSectionIndex {
            //print(currentSectionIndex)
            self.currentSectionIndex = newIndex
            self.previousContentOffset = self.collectionView!.contentOffset
        }
        //print("contentOffset: \(self.collectionView!.contentOffset.y)")
    }

    private var currentScrollDirection: ScrollDirection {
        if let previousContentOffset = self.previousContentOffset
               where self.collectionView!.contentOffset.y < previousContentOffset.y
        { return .Top }
        return .Bottom
    }

    private var currentVisibleContentYOffset: CGFloat {
        let scrollView = self.collectionView!
        var offset = scrollView.contentOffset.y
        //print(offset, self.tileLayout.viewportYOffset)
        if self.edgesForExtendedLayout.contains(.Top) {
            offset += self.tileLayout.viewportYOffset
        }
        return offset
    }

    // MARK: UIScrollViewDelegate

    override func scrollViewDidScroll(scrollView: UIScrollView) {
        guard self.events != nil else { return }
        self.updateTitleViewContentOffsetToSectionHeader()
    }

    // MARK: NavigationTitleScrollViewDataSource

    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int {
        guard let months = self.months where months.count > 0 else { return 1 }
        return self.numberOfSectionsInCollectionView(self.collectionView!)
    }

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView? {
        var titleText: NSString?
        var label: UILabel?
        if let month = self.months?[index] as? NSDate {
            titleText = MonthHeaderView.formattedTextForText(NSDateFormatter.monthFormatter.stringFromDate(month))
        }
        if let info = NSBundle.mainBundle().infoDictionary {
            // Default to app title.
            titleText = titleText ?? (info["CFBundleDisplayName"] as? NSString) ?? (info["CFBundleName"] as? NSString)
        }
        if let text = titleText {
            label = self.titleView.newItemOfType(.Label, withText: MonthHeaderView.formattedTextForText(text)) as? UILabel
            label?.accessibilityLabel = text as String
        }
        return label
    }

    // MARK: NavigationTitleScrollViewDelegate

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, didChangeVisibleItem visibleItem: UIView) {}
}

// MARK: - Data

extension MonthsViewController {

    private func fetchEvents() {
        guard !self.isFetching else { return }
        self.isFetching = true

        let componentsToAdd = NSDateComponents(); componentsToAdd.year = 1
        let endDate = NSCalendar.currentCalendar().dateByAddingComponents(
            componentsToAdd, toDate: self.currentDate, options: []
        )!

        do {
            try self.eventManager.fetchEventsFromDate(untilDate: endDate) {
                self.didFetchEvents()
                self.isFetching = false
            }
        } catch { self.isFetching = false }
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.events?.daysForMonthAtIndex(section)?.count ?? 0
    }
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.months?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(DayViewCell), forIndexPath: indexPath)
        if let cell = cell as? DayViewCell,
               dayDate = self.events?.dayAtIndexPath(indexPath),
               dayEvents = self.events?.eventsForDayAtIndexPath(indexPath)
        {
            cell.setAccessibilityLabelsWithIndexPath(indexPath)
            cell.isToday = dayDate.isEqualToDate(self.currentDate.dayDate)
            cell.dayText = NSDateFormatter.dayFormatter.stringFromDate(dayDate)
            cell.numberOfEvents = dayEvents.count
        }
        return cell
    }
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                  atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
    {
        let view = collectionView.dequeueReusableSupplementaryViewOfKind( kind,
            withReuseIdentifier: String(MonthHeaderView), forIndexPath: indexPath)
        if case kind = UICollectionElementKindSectionHeader,
           let headerView = view as? MonthHeaderView,
               month = self.months?[indexPath.section] as? NSDate
               where indexPath.section > 0
        {
            headerView.monthName = NSDateFormatter.monthFormatter.stringFromDate(month)
            headerView.monthLabel.textColor = self.appearanceManager.lightGrayTextColor
        }
        return view
    }

}

// MARK: - Day Cell

extension MonthsViewController {

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

extension MonthsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
         referenceSizeForHeaderInSection section: Int) -> CGSize
    {
        guard section > 0 else { return CGSizeZero }
        return (collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize ?? CGSizeZero
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return self.tileLayout.sizeForItemAtIndexPath(indexPath)
    }

}
