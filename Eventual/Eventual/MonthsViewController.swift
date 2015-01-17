//
//  ETMonthsViewController.swift
//  Eventual
//
//  Created by Nest Master on 6/2/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import EventKit

@objc(ETMonthsViewController) class MonthsViewController: UICollectionViewController {
    
    // MARK: State
    
    private var currentDate: NSDate = NSDate()
    private var currentDayDate: NSDate {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(
            calendar.components(.DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit, fromDate: self.currentDate)
        )!
    }
    private var currentIndexPath: NSIndexPath?
    private var currentSectionIndex: Int = 0
    private var currentSelectedDayDate: NSDate?
    
    // MARK: Add Event
    
    @IBOutlet var backgroundTapRecognizer: UITapGestureRecognizer!
    var interactiveBackgroundViewTrait: CollectionViewInteractiveBackgroundViewTrait!
    
    // MARK: Data Source
    
    private let CellReuseIdentifier = "Day"
    private let HeaderReuseIdentifier = "Month"
    
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
    
    private var dataSource: ETEventByMonthAndDayCollection? {
        return self.eventManager.eventsByMonthsAndDays
    }
    
    private var allMonthDates: [NSDate]? {
        if let dataSource = self.dataSource {
            return dataSource[ETEntityCollectionDatesKey]! as? [NSDate]
        }
        return nil
    }

    var autoReloadDataTrait: CollectionViewAutoReloadDataTrait!

    // MARK: Layout
    
    private var tileLayout: CollectionViewTileLayout {
        return self.collectionViewLayout as CollectionViewTileLayout
    }
    
    // MARK: Navigation

    private var customTransitioningDelegate: TransitioningDelegate!
    
    // MARK: Title View
    
    @IBOutlet private var titleView: NavigationTitleScrollView!
    private var previousContentOffset: CGPoint!
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
            name: ETEntitySaveOperationNotification, object: nil
        )
        center.addObserver( self,
            selector: Selector("eventAccessRequestDidComplete:"),
            name: ETEntityAccessRequestNotification, object: nil
        )
    }
    private func tearDown() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        self.customTransitioningDelegate.tearDown()
    }
    
    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAccessibilityLabels()
        // Title.
        self.setUpTitleView()
        // Transition.
        self.customTransitioningDelegate = TransitioningDelegate(animationDelegate: self, interactionDelegate: self)
        self.customTransitioningDelegate.setUp();
        // Traits.
        self.interactiveBackgroundViewTrait = CollectionViewInteractiveBackgroundViewTrait(
            collectionView: self.collectionView!,
            tapRecognizer: self.backgroundTapRecognizer
        )
        self.interactiveBackgroundViewTrait.setUp()
        self.autoReloadDataTrait = CollectionViewAutoReloadDataTrait(collectionView: self.collectionView!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.dayFormatter = nil
        self.monthFormatter = nil
        self.eventManager = nil
        self.customTransitioningDelegate = nil
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
        self.tileLayout.updateViewportYOffset()
        self.cachedHeaderLabelTop = nil
    }

    private func setAccessibilityLabels() {
        self.collectionView!.accessibilityLabel = t(ETLabel.MonthDays.rawValue)
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
        let result: String = (notification.userInfo as [String: AnyObject])[ETEntityAccessRequestNotificationResultKey]! as String
        switch result {
        case ETEntityAccessRequestNotificationGranted:
            self.fetchEvents()
        default:
            fatalError("Unimplemented access result.")
        }
    }
    
}

// MARK: - Navigation

extension MonthsViewController: TransitionAnimationDelegate, TransitionInteractionDelegate {

    // MARK: Actions
    
    @IBAction private func dismissEventViewController(sender: UIStoryboardSegue) {
        if let navigationController = self.presentedViewController as? NavigationController {
            if let indexPath = self.currentIndexPath {
                let isDayRemoved = self.dayDateAtIndexPath(indexPath) != self.currentSelectedDayDate
                // Just do the default transition if the snapshotReferenceView is illegitimate.
                if isDayRemoved {
                    navigationController.transitioningDelegate = nil
                    navigationController.modalPresentationStyle = .FullScreen
                }
            }
        }
        self.customTransitioningDelegate.isInteractive = false
        self.dismissViewControllerAnimated(true, completion: {
            self.customTransitioningDelegate.isInteractive = true
        })
    }

    @IBAction private func requestAddingEvent(sender: AnyObject?) {
        if let recognizer = sender as? UITapGestureRecognizer {
            if recognizer === self.backgroundTapRecognizer {
                //NSLog("Background tap.")
                dispatch_after(0.1) {
                    self.interactiveBackgroundViewTrait.toggleHighlighted(false)
                    self.performSegueWithIdentifier(ETSegue.AddEvent.rawValue, sender: sender)
                }
            }
        }
    }
    
    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.destinationViewController is NavigationController &&
           self.currentIndexPath != nil
        {
            let navigationController = segue.destinationViewController as NavigationController
            if segue.identifier == ETSegue.ShowDay.rawValue {
                navigationController.transitioningDelegate = self.customTransitioningDelegate
                navigationController.modalPresentationStyle = .Custom
                if let viewController = navigationController.viewControllers[0] as? DayViewController {
                    var indexPath: NSIndexPath!
                    if let currentIndexPath = self.currentIndexPath {
                        indexPath = currentIndexPath
                    } else {
                        let indexPaths = self.collectionView!.indexPathsForSelectedItems() as [NSIndexPath]
                        indexPath = indexPaths.first
                    }
                    if indexPath == nil {
                        fatalError("Day index path required.")
                    }
                    viewController.dayDate = self.dayDateAtIndexPath(indexPath)
                    self.currentSelectedDayDate = viewController.dayDate
                }
                if sender is DayViewCell {
                    self.customTransitioningDelegate.isInteractive = false
                }
            }
        }
        switch segue.identifier! {
        case ETSegue.AddEvent.rawValue:
            self.currentIndexPath = nil // Reset.
        default: break
        }
        super.prepareForSegue(segue, sender: sender)
    }

    // MARK: TransitionAnimationDelegate

    func animatedTransition(transition: AnimatedTransition,
         snapshotReferenceViewWhenReversed reversed: Bool) -> UIView
    {
        if let indexPath = self.currentIndexPath {
            if let cell = self.collectionView!.cellForItemAtIndexPath(indexPath) {
                return cell
            }
        }
        return self.collectionView!
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
        var view: UIView?
        if let indexPath = self.collectionView!.indexPathForItemAtPoint(location) {
            view = self.collectionView!.cellForItemAtIndexPath(indexPath)
        }
        return view
    }

    // TODO: Going back.
    func beginInteractiveTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView)
    {
        let cell = referenceView as DayViewCell
        if let indexPath = self.collectionView!.indexPathForCell(cell) {
            self.currentIndexPath = indexPath
            self.performSegueWithIdentifier(ETSegue.ShowDay.rawValue, sender: transition)
        }
    }

}

// MARK: - Title View

enum ETScrollDirection {
    case Top, Left, Bottom, Right
}

extension MonthsViewController: UIScrollViewDelegate,
    NavigationTitleScrollViewDataSource, NavigationTitleScrollViewDelegate
{
    
    private func setUpTitleView() {
        self.titleView.delegate = self
        self.titleView.dataSource = self
    }
    
    private func updateTitleView() {
        // Update title with section header.
        let currentIndex = self.currentSectionIndex
        let titleHeight = self.titleView.frame.size.height
        var titleBottom = self.currentVisibleContentYOffset
        // NOTE: It turns out the spacing between the bar and title is about the same
        // size as the title item's top padding, so they cancel each other out (minus
        // spacing, plus padding).
        var titleTop = titleBottom - titleHeight
        func headerTopForIndexPath(indexPath: NSIndexPath) -> CGFloat? {
            let headerKind = UICollectionElementKindSectionHeader
            if let headerLayoutAttributes = self.tileLayout.layoutAttributesForSupplementaryViewOfKind(headerKind, atIndexPath: indexPath) {
                let headerLabelTop = self.cachedHeaderLabelTop ?? (
                    (self.collectionView!.dequeueReusableSupplementaryViewOfKind( headerKind,
                        withReuseIdentifier: HeaderReuseIdentifier, forIndexPath: indexPath
                        ) as MonthHeaderView).monthLabel.frame.origin.y
                )
                self.cachedHeaderLabelTop = headerLabelTop
                return headerLayoutAttributes.frame.origin.y + headerLabelTop
            }
            return nil
        }
        var offset: CGFloat?
        var offsetChange: CGFloat?
        var index: Int?
        switch self.currentScrollDirection {
        case .Top:
            let previousIndex = currentIndex - 1
            if previousIndex < 0 { return }
            if let headerTop = headerTopForIndexPath(NSIndexPath(forItem: 0, inSection: currentIndex)) {
                offsetChange = titleTop - headerTop
                if titleBottom < headerTop {
                    offset = CGFloat(previousIndex) * titleHeight
                    index = previousIndex
                } else if titleTop < headerTop && abs(offsetChange!) <= titleHeight {
                    offset = CGFloat(currentIndex) * titleHeight + offsetChange!
                }
            }
        case .Bottom:
            let nextIndex = currentIndex + 1
            if nextIndex >= self.collectionView!.numberOfSections() { return }
            if let headerTop = headerTopForIndexPath(NSIndexPath(forItem: 0, inSection: nextIndex)) {
                offsetChange = titleBottom - headerTop
                if titleTop > headerTop {
                    offset = CGFloat(nextIndex) * titleHeight
                    index = nextIndex
                } else if titleBottom > headerTop && abs(offsetChange!) <= titleHeight {
                    offset = CGFloat(currentIndex) * titleHeight + offsetChange!
                }
            }
        default:
            fatalError("Unsupported direction.")
        }
        if let currentTitleYOffset = offset {
            let offsetPoint = CGPoint(x: self.titleView.contentOffset.x, y: currentTitleYOffset)
            self.titleView.setContentOffset(offsetPoint, animated: false)
        }
        if let currentSectionIndex = index {
            if currentSectionIndex != self.currentSectionIndex {
                //println(currentSectionIndex)
                self.currentSectionIndex = currentSectionIndex
                self.previousContentOffset = self.collectionView!.contentOffset
            }
        }
        //println("Offset: \(self.collectionView!.contentOffset)")
    }
    
    private var currentScrollDirection: ETScrollDirection {
        let scrollView = self.collectionView!
        return ((self.previousContentOffset != nil && scrollView.contentOffset.y < self.previousContentOffset.y)
                ? .Top : .Bottom)
    }
    
    private var currentVisibleContentYOffset: CGFloat {
        let scrollView = self.collectionView!
        var offset = scrollView.contentOffset.y
        if let navigationController = self.navigationController {
            if (self.edgesForExtendedLayout.rawValue & UIRectEdge.Top.rawValue) != 0 {
                offset += self.tileLayout.viewportYOffset
            }
        }
        return offset
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if let dataSource = self.dataSource {
            self.updateTitleView()
        }
    }
    
    // MARK: NavigationTitleScrollViewDataSource
    
    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int {
        if self.allMonthDates != nil && !self.allMonthDates!.isEmpty {
            return self.numberOfSectionsInCollectionView(self.collectionView!)
        }
        return 1
    }
    
    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView? {
        var titleText: NSString!
        if let monthDate = self.allMonthDates?[index] {
            titleText = MonthHeaderView.formattedTextForText(self.monthFormatter.stringFromDate(monthDate))
        }
        if titleText == nil {
            // Default to app title.
            let info = NSBundle.mainBundle().infoDictionary!
            titleText = (info["CFBundleDisplayName"]? as? NSString) ?? (info["CFBundleName"] as? NSString)
        }
        if let item = self.titleView.newItemOfType(.Label, withText: MonthHeaderView.formattedTextForText(titleText)) {
            return item
        }
        return nil
    }
    
    // MARK: NavigationTitleScrollViewDelegate
    
    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, didChangeVisibleItem visibleItem: UIView) {}
}

// MARK: - Add Event

extension MonthsViewController: UIGestureRecognizerDelegate, UIScrollViewDelegate {

    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldReceiveTouch touch: UITouch!) -> Bool {
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

extension MonthsViewController: UICollectionViewDataSource {
    
    private func fetchEvents() {
        let componentsToAdd = NSDateComponents()
        componentsToAdd.year = 1
        let endDate = NSCalendar.currentCalendar().dateByAddingComponents(
            componentsToAdd, toDate: self.currentDate, options: nil
            )!
        let operation: NSOperation = self.eventManager.fetchEventsFromDate(untilDate: endDate) {
            //NSLog("Events: %@", self._eventManager.eventsByMonthsAndDays!)
            self.collectionView!.reloadData()
            self.titleView.refreshSubviews()
        }
    }
    
    private func allDateDatesForMonthAtIndex(index: Int) -> [NSDate]? {
        if self.dataSource == nil { return nil }
        if let monthsDays = self.dataSource![ETEntityCollectionDaysKey]! as? [[String: [AnyObject]]] {
            if monthsDays.count > index {
                let days = monthsDays[index] as [String: [AnyObject]]
                return days[ETEntityCollectionDatesKey]! as? [NSDate]
            }
        }
        return nil
    }
    private func dayDateAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        if self.dataSource == nil { return nil }
        if let monthsDays = self.dataSource![ETEntityCollectionDaysKey]! as? [[String: [AnyObject]]] {
            let days = monthsDays[indexPath.section] as [String: [AnyObject]]
            let daysDates = days[ETEntityCollectionDatesKey]! as [NSDate]
            return daysDates[indexPath.item]
        }
        return nil
    }
    private func dayEventsAtIndexPath(indexPath: NSIndexPath) -> [EKEvent]? {
        if self.dataSource == nil { return nil }
        if let monthsDays = self.dataSource![ETEntityCollectionDaysKey]! as? [[String: [AnyObject]]] {
            let days = monthsDays[indexPath.section] as [String: [AnyObject]]
            let daysEvents = days[ETEntityCollectionEventsKey]! as [[EKEvent]]
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellReuseIdentifier, forIndexPath: indexPath) as DayViewCell
        cell.setAccessibilityLabelsWithIndexPath(indexPath)
        if let dayDate = self.dayDateAtIndexPath(indexPath) {
            if let dayEvents = self.dayEventsAtIndexPath(indexPath) {
                cell.isToday = dayDate.isEqualToDate(self.currentDayDate)
                cell.dayText = self.dayFormatter.stringFromDate(dayDate)
                cell.numberOfEvents = dayEvents.count
            }
        }
        return cell
    }
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                  atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
    {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: HeaderReuseIdentifier, forIndexPath: indexPath) as MonthHeaderView
            if let months = self.allMonthDates {
                let monthDate = months[indexPath.section]
                headerView.monthName = self.monthFormatter.stringFromDate(monthDate)
            }
            headerView.monthLabel.textColor = self.appearanceManager.lightGrayTextColor
            return headerView
        default:
            let hiddenView = UICollectionReusableView(frame: CGRectZero)
            hiddenView.hidden = true
            return hiddenView
        }
    }
    
}

// MARK: - Day Cell

extension MonthsViewController: UICollectionViewDelegate {
    
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        self.currentIndexPath = indexPath
        return true
    }
    
}

// MARK: - Layout

extension MonthsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!,
         referenceSizeForHeaderInSection section: Int) -> CGSize
    {
        return (section == 0) ? CGSizeZero : (collectionViewLayout as UICollectionViewFlowLayout).headerReferenceSize
    }

}

// MARK: - Minor classes

@objc(ETMonthHeaderView) class MonthHeaderView: UICollectionReusableView {
    
    var monthName: String? {
        didSet {
            if oldValue == self.monthName { return }
            if let monthName = self.monthName {
                self.monthLabel.text = MonthHeaderView.formattedTextForText(monthName)
            }
        }
    }
    
    @IBOutlet private var monthLabel: UILabel!
    
    override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
    class func formattedTextForText(text: NSString) -> NSString {
        return text.uppercaseString
    }
    
}