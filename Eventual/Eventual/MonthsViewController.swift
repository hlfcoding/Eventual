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
    
    private var currentDate: NSDate = NSDate.date()
    private lazy var currentDayDate: NSDate = {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(
            calendar.components(.DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit, fromDate: self.currentDate)
        )!
    }()
    private var currentIndexPath: NSIndexPath?
    private var currentSectionIndex: Int = 0
    
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

    // MARK: Layout
    
    private var tileLayout: CollectionViewTileLayout {
        return self.collectionViewLayout as CollectionViewTileLayout
    }
    
    // MARK: Navigation
    
    private lazy var transitionCoordinator: ZoomTransitionCoordinator! = {
        var transitionCoordinator = ZoomTransitionCoordinator()
        transitionCoordinator.delegate = self.tileLayout
        return transitionCoordinator
    }()
    
    // MARK: Title View
    
    @IBOutlet private var titleView: NavigationTitleScrollView!
    private var previousContentOffset: CGPoint!
    
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
        center.addObserver(self, selector: Selector("eventAccessRequestDidComplete:"), name: ETEntityAccessRequestNotification, object: nil)
        center.addObserver(self, selector: Selector("eventSaveOperationDidComplete:"), name: ETEntitySaveOperationNotification, object: nil)
    }
    private func tearDown() {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
    }
    
    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAccessibilityLabels()
        self.setUpTitleView()
        self.interactiveBackgroundViewTrait = CollectionViewInteractiveBackgroundViewTrait(
            collectionView: self.collectionView!,
            tapRecognizer: self.backgroundTapRecognizer
        )
        self.interactiveBackgroundViewTrait.setUp()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.dayFormatter = nil
        self.monthFormatter = nil
        self.eventManager = nil
        self.transitionCoordinator = nil
    }

    private func setAccessibilityLabels() {
        self.collectionView!.accessibilityLabel = t(ETLabel.MonthDays.toRaw())
        self.collectionView!.isAccessibilityElement = true
    }
    
    // MARK: Handlers
    
    func eventAccessRequestDidComplete(notification: NSNotification) {
        let result: String = (notification.userInfo as [String: AnyObject])[ETEntityAccessRequestNotificationResultKey]! as String
        switch result {
        case ETEntityAccessRequestNotificationGranted:
            let components = NSDateComponents()
            components.year = 1
            let endDate = NSCalendar.currentCalendar().dateByAddingComponents(
                components, toDate: self.currentDate, options: .fromMask(0))!
            let operation: NSOperation = self.eventManager.fetchEventsFromDate(untilDate: endDate) {
                //NSLog("Events: %@", self._eventManager.eventsByMonthsAndDays!)
                self.collectionView!.reloadData()
                self.titleView.refreshSubviews()
            }
        default:
            fatalError("Unimplemented access result.")
        }
    }
    
    func eventSaveOperationDidComplete(notification: NSNotification) {
        let userInfo = notification.userInfo as [String: AnyObject]
        let type: EKEntityType = userInfo[ETEntityOperationNotificationTypeKey]! as EKEntityType
        switch type {
        case EKEntityTypeEvent:
            let event: EKEvent = userInfo[ETEntityOperationNotificationDataKey]! as EKEvent
            self.collectionView!.reloadData()
        default:
            fatalError("Unimplemented entity type.")
        }
    }
    
}

// MARK: - Navigation

extension MonthsViewController {

    private func setUpTransitionForCellAtIndexPath(indexPath: NSIndexPath) {
        let coordinator = self.transitionCoordinator
        let offset = self.collectionView!.contentOffset
        coordinator.zoomContainerView = self.navigationController!.view
        if let cell = self.collectionView!.cellForItemAtIndexPath(indexPath) as? DayViewCell {
            coordinator.zoomedOutView = cell
            coordinator.zoomedOutFrame = CGRectOffset(cell.frame, -offset.x, -offset.y)
        }
    }
    
    // MARK: Actions
    
    @IBAction private func dismissEventViewController(sender: UIStoryboardSegue) {
        if let indexPath = self.currentIndexPath {
            self.setUpTransitionForCellAtIndexPath(indexPath)
            self.transitionCoordinator.isZoomReversed = true
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    @IBAction private func requestAddingEvent(sender: AnyObject?) {
        if let recognizer = sender as? UITapGestureRecognizer {
            if recognizer === self.backgroundTapRecognizer {
                //NSLog("Background tap.")
                dispatch_after(0.1) {
                    self.interactiveBackgroundViewTrait.toggleHighlighted(false)
                    self.performSegueWithIdentifier(ETSegue.AddDay.toRaw(), sender: sender)
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
            if segue.identifier == ETSegue.ShowDay.toRaw() {
                self.setUpTransitionForCellAtIndexPath(self.currentIndexPath!)
                navigationController.transitioningDelegate = self.transitionCoordinator
                navigationController.modalPresentationStyle = .Custom
                if let viewController = navigationController.viewControllers[0] as? DayViewController {
                    let indexPaths = self.collectionView!.indexPathsForSelectedItems() as [NSIndexPath]
                    if indexPaths.isEmpty { return }
                    let indexPath = indexPaths[0]
                    viewController.dayDate = self.dayDateAtIndexPath(indexPath)
                    viewController.dayEvents = self.dayEventsAtIndexPath(indexPath)
                }
            }
        }
        switch segue.identifier {
        case ETSegue.AddDay.toRaw():
            self.currentIndexPath = nil // Reset.
        default: break
        }
        super.prepareForSegue(segue, sender: sender)
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
        let barHeight = self.navigationController!.navigationBar.frame.size.height
        let barAndTitleSpacing = (barHeight - titleHeight) / 2.0
        var titleBottom = self.currentVisibleContentYOffset - barAndTitleSpacing + 1.0
        var titleTop = titleBottom - titleHeight
        func headerTopForIndexPath(indexPath: NSIndexPath) -> CGFloat? {
            return self.collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(
                   UICollectionElementKindSectionHeader, atIndexPath:indexPath)?.frame.origin.y
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
            self.currentSectionIndex = currentSectionIndex
            self.previousContentOffset = self.collectionView!.contentOffset
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
            if (self.edgesForExtendedLayout.toRaw() & UIRectEdge.Top.toRaw()) != 0 {
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
            let info = NSBundle.mainBundle().infoDictionary
            titleText = (info["CFBundleDisplayName"]? ?? info["CFBundleName"]!) as String
        }
        if let item = self.titleView.newItemOfType(.Label, withText: titleText) {
            return item
        }
        return nil
    }
    
    // MARK: NavigationTitleScrollViewDelegate
    
    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, didChangeVisibleItem visibleItem: UIView) {
        
    }
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