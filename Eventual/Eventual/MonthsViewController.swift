//
//  MonthsViewController.swift
//  Eventual
//
//  Created by Peng Wang on 6/2/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import EventKit

class MonthsViewController: UICollectionViewController {

    // MARK: State

    private var currentDate: NSDate = NSDate()
    private var currentIndexPath: NSIndexPath?
    private var currentSectionIndex: Int = 0
    private var currentSelectedDayDate: NSDate?

    private var isFetching = false

    // MARK: Add Event

    @IBOutlet var backgroundTapRecognizer: UITapGestureRecognizer!
    var interactiveBackgroundViewTrait: CollectionViewInteractiveBackgroundViewTrait!

    // MARK: Data Source

    private static let CellReuseIdentifier = "Day"
    private static let HeaderReuseIdentifier = "Month"

    private lazy var dayFormatter: NSDateFormatter! = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    private lazy var monthFormatter: NSDateFormatter! = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    private lazy var eventManager: EventManager! = {
        return EventManager.defaultManager()
    }()

    private var dataSource: DateIndexedEventCollection? {
        return self.eventManager.eventsByMonthsAndDays
    }

    private var allMonthDates: [NSDate]? {
        return self.dataSource?[DatesKey] as? [NSDate]
    }

    var autoReloadDataTrait: CollectionViewAutoReloadDataTrait!

    // MARK: Layout

    private var tileLayout: CollectionViewTileLayout {
        return self.collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: Navigation

    private var customTransitioningDelegate: TransitioningDelegate!
    @IBOutlet var backToTopTapRecognizer: UITapGestureRecognizer!

    // MARK: Title View

    @IBOutlet private var titleView: NavigationTitleScrollView!
    private var previousContentOffset: CGPoint?

    // MARK: Appearance
    private lazy var appearanceManager: AppearanceManager! = {
        return AppearanceManager.defaultManager()
    }()

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
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver( self,
            selector: Selector("applicationDidBecomeActive:"),
            name: UIApplicationDidBecomeActiveNotification, object: nil
        )
        center.addObserver( self,
            selector: Selector("entityOperationDidComplete:"),
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
        self.customTransitioningDelegate = TransitioningDelegate(animationDelegate: self, interactionDelegate: self)
        // Traits.
        self.interactiveBackgroundViewTrait = CollectionViewInteractiveBackgroundViewTrait(
            collectionView: self.collectionView!,
            tapRecognizer: self.backgroundTapRecognizer
        )
        self.interactiveBackgroundViewTrait.setUp()
        self.autoReloadDataTrait = CollectionViewAutoReloadDataTrait(collectionView: self.collectionView!)
        self.fetchEvents()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.customTransitioningDelegate.isInteractionEnabled = true
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.presentedViewController == nil {
            self.customTransitioningDelegate.isInteractionEnabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.dayFormatter = nil
        self.monthFormatter = nil
        self.eventManager = nil
        self.customTransitioningDelegate = nil
    }

    private func setAccessibilityLabels() {
        self.collectionView!.accessibilityLabel = t(Label.MonthDays.rawValue)
    }

    // MARK: Handlers

    func applicationDidBecomeActive(notification: NSNotification) {
        self.fetchEvents()
    }

    func entityOperationDidComplete(notification: NSNotification) {
        self.autoReloadDataTrait.reloadFromEntityOperationNotification(notification)
        self.titleView.refreshSubviews()
    }

    func eventAccessRequestDidComplete(notification: NSNotification) {
        guard let result = (notification.userInfo as? [String: AnyObject])?[ResultKey] as? String
              else { return }
        switch result {
        case EntityAccessGranted:
            self.fetchEvents()
        default:
            fatalError("Unimplemented access result.")
        }
    }

}

// MARK: - Navigation

extension MonthsViewController: TransitionAnimationDelegate, TransitionInteractionDelegate {

    // MARK: Actions

    @IBAction private func unwindToMonths(sender: UIStoryboardSegue) {
        if let indexPath = self.currentIndexPath,
               navigationController = self.presentedViewController as? NavigationController
        {
            let isDayRemoved = self.dayDateAtIndexPath(indexPath) != self.currentSelectedDayDate
            // Just do the default transition if the snapshotReferenceView is illegitimate.
            if isDayRemoved {
                navigationController.transitioningDelegate = nil
                navigationController.modalPresentationStyle = .FullScreen
            }
        }
    }

    @IBAction private func requestAddingEvent(sender: UITapGestureRecognizer) {
        dispatch_after(0.1) {
            self.interactiveBackgroundViewTrait.toggleHighlighted(false)
            self.performSegueWithIdentifier(Segue.AddEvent.rawValue, sender: sender)
        }
    }

    @IBAction private func returnBackToTop(sender: UITapGestureRecognizer) {
        self.collectionView!.setContentOffset(
            CGPoint(x: 0.0, y: -self.collectionView!.contentInset.top),
            animated: true
        )
    }

    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        super.prepareForSegue(segue, sender: sender)

        guard let rawIdentifier = segue.identifier,
                  identifier = Segue(rawValue: rawIdentifier)
              else { return }

        switch identifier {

        case .ShowDay:
            guard let navigationController = segue.destinationViewController as? NavigationController,
                  viewController = navigationController.topViewController as? DayViewController,
                  firstIndexPath = self.collectionView?.indexPathsForSelectedItems()?.first
                  else { break }

            navigationController.transitioningDelegate = self.customTransitioningDelegate
            navigationController.modalPresentationStyle = .Custom
            if sender is DayViewCell {
                self.customTransitioningDelegate.isInteractive = false
            }

            let indexPath = self.currentIndexPath ?? firstIndexPath
            viewController.dayDate = self.dayDateAtIndexPath(indexPath)
            self.currentSelectedDayDate = viewController.dayDate

        case .AddEvent:
            self.currentIndexPath = nil // Reset.

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
         willCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)
    {
        guard let cell = snapshotReferenceView as? CollectionViewTileCell else { return }
        self.tileLayout.restoreBordersToTileCellForSnapshot(cell)
    }

    func animatedTransition(transition: AnimatedTransition,
         didCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)
    {
        guard let cell = snapshotReferenceView as? CollectionViewTileCell else { return }
        self.tileLayout.restoreOriginalBordersToTileCell(cell)
    }

    // MARK: TransitionInteractionDelegate

    func interactiveTransition(transition: InteractiveTransition,
         windowForGestureRecognizer recognizer: UIGestureRecognizer) -> UIWindow
    {
        return UIApplication.sharedApplication().keyWindow!
    }

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

    // TODO: Going back.
    func beginInteractivePresentationTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)
    {
        if let cell = referenceView as? DayViewCell,
               indexPath = self.collectionView!.indexPathForCell(cell)
        {
            self.currentIndexPath = indexPath
            self.performSegueWithIdentifier(Segue.ShowDay.rawValue, sender: transition)
        }
    }

    func beginInteractiveDismissalTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)
    {}

    func interactiveTransition(transition: InteractiveTransition,
         destinationScaleForSnapshotReferenceView referenceView: UIView?,
         contextView: UIView, reversed: Bool) -> CGFloat
    {
        guard reversed,
              let zoomTransition = transition as? InteractiveZoomTransition,
                  indexPath = self.currentIndexPath
              else { return -1.0 }
        let cell = self.collectionView!.guaranteedCellForItemAtIndexPath(indexPath)
        return cell.frame.size.width / zoomTransition.pinchSpan
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
        let titleHeight = self.titleView.frame.size.height
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
        guard self.dataSource != nil else { return }
        self.updateTitleViewContentOffsetToSectionHeader()
    }

    // MARK: NavigationTitleScrollViewDataSource

    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int {
        guard let dates = self.allMonthDates where !dates.isEmpty else { return 1 }
        return self.numberOfSectionsInCollectionView(self.collectionView!)
    }

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView? {
        var titleText: NSString?
        var label: UILabel?
        if let monthDate = self.allMonthDates?[index] {
            titleText = MonthHeaderView.formattedTextForText(self.monthFormatter.stringFromDate(monthDate))
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

// MARK: - Add Event

extension MonthsViewController: UIGestureRecognizerDelegate {

    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer === self.backgroundTapRecognizer {
            self.interactiveBackgroundViewTrait.handleTap()
            //NSLog("Begin possible background tap.")
        }
        return true
    }

    // MARK: UIScrollViewDelegate

    override func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint,
                  targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        self.interactiveBackgroundViewTrait
            .handleScrollViewWillEndDragging(scrollView, withVelocity: velocity,
                targetContentOffset: targetContentOffset)
    }

}

// MARK: - Data

extension MonthsViewController {

    private func fetchEvents() {
        guard !self.isFetching else { return }
        self.isFetching = true
        let componentsToAdd = NSDateComponents()
        componentsToAdd.year = 1
        let endDate = NSCalendar.currentCalendar().dateByAddingComponents(
            componentsToAdd, toDate: self.currentDate, options: []
        )!
        self.eventManager.fetchEventsFromDate(untilDate: endDate) {
            //NSLog("Events: %@", self._eventManager.eventsByMonthsAndDays!)
            self.collectionView!.reloadData()
            self.titleView.refreshSubviews()
            self.isFetching = false
        }
    }

    private func allDateDatesForMonthAtIndex(index: Int) -> [NSDate]? {
        guard let days = self.dataSource?[DaysKey]?[index] as? DateIndexedEventCollection
              where self.dataSource?[DaysKey]?.count > index else { return nil }
        return days[DatesKey] as? [NSDate]
    }

    private func daysAtIndexPath(indexPath: NSIndexPath) -> DateIndexedEventCollection? {
        return self.dataSource?[DaysKey]?[indexPath.section] as? DateIndexedEventCollection
    }
    private func dayDateAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        return self.daysAtIndexPath(indexPath)?[DatesKey]?[indexPath.item] as? NSDate
    }
    private func dayEventsAtIndexPath(indexPath: NSIndexPath) -> [EKEvent]? {
        return self.daysAtIndexPath(indexPath)?[EventsKey]?[indexPath.item] as? [EKEvent]
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.allDateDatesForMonthAtIndex(section)?.count ?? 0
    }
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.allMonthDates?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(MonthsViewController.CellReuseIdentifier, forIndexPath: indexPath)
        if let cell = cell as? DayViewCell {
            cell.setAccessibilityLabelsWithIndexPath(indexPath)
        }
        if let cell = cell as? DayViewCell,
               dayDate = self.dayDateAtIndexPath(indexPath),
               dayEvents = self.dayEventsAtIndexPath(indexPath)
        {
            cell.isToday = dayDate.isEqualToDate(self.currentDate.dayDate!)
            cell.dayText = self.dayFormatter.stringFromDate(dayDate)
            cell.numberOfEvents = dayEvents.count
        }
        return cell
    }
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                  atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
    {
        let view = collectionView.dequeueReusableSupplementaryViewOfKind( kind,
            withReuseIdentifier: MonthsViewController.HeaderReuseIdentifier, forIndexPath: indexPath)
        if case kind = UICollectionElementKindSectionHeader,
           let headerView = view as? MonthHeaderView,
               monthDate = self.allMonthDates?[indexPath.section]
               where indexPath.section > 0
        {
            headerView.monthName = self.monthFormatter.stringFromDate(monthDate)
            headerView.monthLabel.textColor = self.appearanceManager.lightGrayTextColor
        }
        return view
    }

}

// MARK: - Day Cell

extension MonthsViewController {

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        self.currentIndexPath = indexPath
        return true
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

}

// MARK: - Minor classes

class MonthHeaderView: UICollectionReusableView {

    var monthName: String? {
        didSet {
            if let monthName = self.monthName where monthName != oldValue {
                self.monthLabel.text = MonthHeaderView.formattedTextForText(monthName)
            }
        }
    }

    @IBOutlet private var monthLabel: UILabel!

    override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }

    class func formattedTextForText(text: NSString) -> String {
        return text.uppercaseString
    }

}
