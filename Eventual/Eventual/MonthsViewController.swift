//
//  MonthsViewController.swift
//  Eventual
//
//  Created by Nest Master on 6/2/14.
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
    
    private var dataSource: EventByMonthAndDayCollection? {
        return self.eventManager.eventsByMonthsAndDays
    }
    
    private var allMonthDates: [NSDate]? {
        if let dataSource = self.dataSource {
            return dataSource[EntityCollectionDatesKey] as! [NSDate]?
        }
        return nil
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
    private var cachedHeaderLabelTop: CGFloat?
    
    // MARK: Appearance
    private lazy var appearanceManager: AppearanceManager! = {
        return AppearanceManager.defaultManager()
    }()
    
    // MARK: - Initializers
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setUp()
    }
    required init(coder aDecoder: NSCoder) {
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
            name: EntityAccessRequestNotification, object: nil
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

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.tileLayout.updateViewportYOffset()
        self.cachedHeaderLabelTop = nil
    }

    private func setAccessibilityLabels() {
        self.collectionView!.accessibilityLabel = t(Label.MonthDays.rawValue)
        self.collectionView!.isAccessibilityElement = true
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
        if let userInfo = notification.userInfo as? [String: AnyObject],
               result = userInfo[EntityAccessRequestNotificationResultKey] as? String
        {
            switch result {
            case EntityAccessRequestNotificationGranted:
                self.fetchEvents()
            default:
                fatalError("Unimplemented access result.")
            }
        }
    }
    
}

// MARK: - Navigation

extension MonthsViewController: TransitionAnimationDelegate, TransitionInteractionDelegate {

    // MARK: Actions
    
    @IBAction private func dismissEventViewController(sender: UIStoryboardSegue) {
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
        self.customTransitioningDelegate.isInteractive = false
        self.dismissViewControllerAnimated(true, completion: {
            self.customTransitioningDelegate.isInteractive = true
        })
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
        if let navigationController = segue.destinationViewController as? NavigationController,
               viewController = navigationController.topViewController as? DayViewController
               where segue.identifier == Segue.ShowDay.rawValue,
           let firstIndexPath = self.collectionView?.indexPathsForSelectedItems()?.first
        {
            let indexPath = self.currentIndexPath ?? firstIndexPath
            navigationController.transitioningDelegate = self.customTransitioningDelegate
            navigationController.modalPresentationStyle = .Custom
            viewController.dayDate = self.dayDateAtIndexPath(indexPath)
            self.currentSelectedDayDate = viewController.dayDate
            if sender is DayViewCell {
                self.customTransitioningDelegate.isInteractive = false
            }
        }
        if let identifier = segue.identifier, case identifier = Segue.AddEvent.rawValue {
            self.currentIndexPath = nil // Reset.
        }
        super.prepareForSegue(segue, sender: sender)
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
        if let cell = snapshotReferenceView as? CollectionViewTileCell {
            self.tileLayout.restoreBordersToTileCellForSnapshot(cell)
        }
    }

    func animatedTransition(transition: AnimatedTransition,
         didCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)
    {
        if let cell = snapshotReferenceView as? CollectionViewTileCell {
            self.tileLayout.restoreOriginalBordersToTileCell(cell)
        }
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
    
    private func updateTitleView() {
        // NOTE: 'header*' refers to section header metrics.
        // Update title view content offset with section header position.
        let currentIndex = self.currentSectionIndex
        let titleHeight = self.titleView.frame.size.height
        var titleBottom = self.currentVisibleContentYOffset
        // NOTE: It turns out the spacing between the bar and title is about the same
        // size as the title item's top padding, so they cancel each other out (minus
        // spacing, plus padding).
        var titleTop = titleBottom - titleHeight
        func headerTopForIndexPath(indexPath: NSIndexPath) -> CGFloat? {
            let kind = UICollectionElementKindSectionHeader
            guard let headerLayoutAttributes = self.tileLayout.layoutAttributesForSupplementaryViewOfKind(kind, atIndexPath: indexPath)
                  else { return nil }
            var headerLabelTop = self.cachedHeaderLabelTop
            // If needed, get and cache the label's top margin from the header view.
            if headerLabelTop == nil,
               let monthHeaderView = self.collectionView( self.collectionView!,
                   viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath
               ) as? MonthHeaderView
            {
                headerLabelTop = monthHeaderView.monthLabel.frame.origin.y
            }
            // The top offset is that margin plus the main layout info's offset.
            guard headerLabelTop != nil else { return nil }
            self.cachedHeaderLabelTop = headerLabelTop
            return headerLayoutAttributes.frame.origin.y + headerLabelTop!
        }
        // The default title view content offset, for most of the time, is to offset
        // to title for current index.
        var index = currentIndex
        var offset: CGFloat = CGFloat(index) * titleHeight
        var offsetChange: CGFloat = 0.0
        // When scrolling in a up/down, if the header has visually gone past and
        // below the title, commit the switch to the previous/next title. If the
        // header hasn't fully passed the title, add the difference to the offset.
        switch self.currentScrollDirection {
        case .Top:
            let previousIndex = currentIndex - 1
            guard previousIndex >= 0 else { return }
            if let headerTop = headerTopForIndexPath(NSIndexPath(forItem: 0, inSection: currentIndex)) {
                offsetChange = titleTop - headerTop
                if headerTop >= titleBottom { index = previousIndex }
                offset = CGFloat(index) * titleHeight
                if headerTop >= titleTop && abs(offsetChange) <= titleHeight { offset += offsetChange }
            }
        case .Bottom:
            let nextIndex = currentIndex + 1
            guard nextIndex < self.collectionView!.numberOfSections() else { return }
            if let headerTop = headerTopForIndexPath(NSIndexPath(forItem: 0, inSection: nextIndex)) {
                offsetChange = titleBottom - headerTop
                if headerTop <= titleTop { index = nextIndex }
                offset = CGFloat(index) * titleHeight
                if headerTop <= titleBottom && abs(offsetChange) <= titleHeight { offset += offsetChange }
            }
        default:
            fatalError("Unsupported direction.")
        }
        // Update with currentTitleYOffset, currentSectionIndex.
        let offsetPoint = CGPoint(x: self.titleView.contentOffset.x, y: offset)
        self.titleView.setContentOffset(offsetPoint, animated: false)
        if index != self.currentSectionIndex {
            //println(currentSectionIndex)
            self.currentSectionIndex = index
            self.previousContentOffset = self.collectionView!.contentOffset
        }
        //println("Offset: \(self.collectionView!.contentOffset)")
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
        if self.edgesForExtendedLayout.contains(.Top) &&
           self.navigationController != nil // FIXME: Smelly check.
        {
            offset += self.tileLayout.viewportYOffset
        }
        return offset
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if self.dataSource != nil { // FIXME: Smelly check.
            self.updateTitleView()
        }
    }
    
    // MARK: NavigationTitleScrollViewDataSource
    
    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int {
        if let dates = self.allMonthDates where !dates.isEmpty {
            return self.numberOfSectionsInCollectionView(self.collectionView!)
        }
        return 1
    }
    
    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView? {
        var titleText: NSString?
        if let monthDate = self.allMonthDates?[index] {
            titleText = MonthHeaderView.formattedTextForText(self.monthFormatter.stringFromDate(monthDate))
        }
        if let info = NSBundle.mainBundle().infoDictionary {
            // Default to app title.
            titleText = titleText ?? (info["CFBundleDisplayName"] as? NSString) ?? (info["CFBundleName"] as? NSString)
        }
        if let text = titleText {
            return self.titleView.newItemOfType(.Label, withText: MonthHeaderView.formattedTextForText(text))
        }
        return nil
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
        let componentsToAdd = NSDateComponents()
        componentsToAdd.year = 1
        let endDate = NSCalendar.currentCalendar().dateByAddingComponents(
            componentsToAdd, toDate: self.currentDate, options: []
        )!
        self.eventManager.fetchEventsFromDate(untilDate: endDate) {
            //NSLog("Events: %@", self._eventManager.eventsByMonthsAndDays!)
            self.collectionView!.reloadData()
            self.titleView.refreshSubviews()
        }
    }
    
    private func allDateDatesForMonthAtIndex(index: Int) -> [NSDate]? {
        if let dataSource = self.dataSource,
               monthsDays = dataSource[EntityCollectionDaysKey] as? [NSDictionary]
               where monthsDays.count > index,
           let days = monthsDays[index] as? [String: [AnyObject]],
               allDates = days[EntityCollectionDatesKey] as? [NSDate]
        {
            return allDates
        }
        return nil
    }
    private func dayDateAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        if let dataSource = self.dataSource,
               monthsDays = dataSource[EntityCollectionDaysKey] as? [NSDictionary],
               days = monthsDays[indexPath.section] as? [String: [AnyObject]],
               daysDates = days[EntityCollectionDatesKey] as? [NSDate]
        {
            return daysDates[indexPath.item]
        }
        return nil
    }
    private func dayEventsAtIndexPath(indexPath: NSIndexPath) -> [EKEvent]? {
        if let dataSource = self.dataSource,
               monthsDays = dataSource[EntityCollectionDaysKey] as? [NSDictionary],
               days = monthsDays[indexPath.section] as? [String: [AnyObject]],
               daysEvents = days[EntityCollectionEventsKey] as? [[EKEvent]]
        {
            return daysEvents[indexPath.item]
        }
        return nil
    }

    // MARK: UICollectionViewDataSource
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var number = 0
        if let monthDays = self.allDateDatesForMonthAtIndex(section) {
            number = monthDays.count
        }
        return number
    }
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        var number = 0
        if let months = self.allMonthDates {
            number = months.count
        }
        return number
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(MonthsViewController.CellReuseIdentifier, forIndexPath: indexPath) as UICollectionViewCell
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