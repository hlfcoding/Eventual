//
//  ETMonthsViewController.swift
//  Eventual
//
//  Created by Nest Master on 6/2/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
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
        )
    }()
    private var currentIndexPath: NSIndexPath?
    private var currentSectionIndex: Int? {
    didSet {
        if self.currentSectionIndex == oldValue { return }
        self.updateTitleView()
    }
    }
    
    // MARK: Add Event
    
    @IBOutlet private weak var backgroundTapRecognizer: UITapGestureRecognizer!
    @IBOutlet private weak var titleView: NavigationTitleView!
    private var originalBackgroundColor: UIColor!
    private let highlightedBackgroundColor = UIColor(white: 0.0, alpha: 0.05)
    
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
    
    // TODO: Make class constants when possible.
    private let DayGutter = 0.0 as CGFloat
    private let MonthGutter = 50.0 as CGFloat
    
    private var cellSize: CGSize!
    private var numberOfColumns: Int!

    // MARK: Navigation
    
    private lazy var transitionCoordinator: ZoomTransitionCoordinator! = {
        return ZoomTransitionCoordinator()
    }()
    
    // MARK: Title View
    
    private var previousContentOffset: CGPoint!
    private var viewportYOffset: CGFloat!
    
    // MARK: Initializers
    
    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setUp()
    }
    init(coder aDecoder: NSCoder!) {
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
        self.setUpBackgroundView()
        self.updateMeasures()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.dayFormatter = nil
        self.monthFormatter = nil
        self.eventManager = nil
        self.transitionCoordinator = nil
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
        self.updateMeasures()
    }
    
    private func setAccessibilityLabels() {
        self.collectionView.accessibilityLabel = ETLabelMonthDays // TODO: NSLocalizedString broken.
        self.collectionView.isAccessibilityElement = true
    }
    
    // MARK: Handlers
    
    private func eventAccessRequestDidComplete(notification: NSNotification) {
        let result: String = notification.userInfo[ETEntityAccessRequestNotificationResultKey]! as String
        switch result {
        case ETEntityAccessRequestNotificationGranted:
            let components = NSDateComponents()
            components.year = 1
            let endDate: NSDate = NSCalendar.currentCalendar().dateByAddingComponents(
                components, toDate: self.currentDate, options: NSCalendarOptions.fromMask(0))
            let operation: NSOperation = self.eventManager.fetchEventsFromDate(untilDate: endDate) {
                //NSLog("Events: %@", self._eventManager.eventsByMonthsAndDays!)
                self.collectionView.reloadData()
                self.updateTitleView()
            }
        default:
            fatalError("Unimplemented access result.")
        }
    }
    
    private func eventSaveOperationDidComplete(notification: NSNotification) {
        let type: EKEntityType = notification.userInfo[ETEntityOperationNotificationTypeKey]! as EKEntityType
        switch type {
        case EKEntityTypeEvent:
            let event: EKEvent = notification.userInfo[ETEntityOperationNotificationDataKey]! as EKEvent
            self.eventManager.invalidateDerivedCollections()
            self.collectionView.reloadData()
        default:
            fatalError("Unimplemented entity type.")
        }
    }
    
}

extension MonthsViewController { // MARK: Navigation

    private func setUpTransitionForCellAtIndexPath(indexPath: NSIndexPath) {
        let coordinator = self.transitionCoordinator
        let offset = self.collectionView.contentOffset
        coordinator.zoomContainerView = self.navigationController.view
        coordinator.zoomedOutView = self.collectionView.cellForItemAtIndexPath(indexPath)
        coordinator.zoomedOutFrame = CGRectOffset(coordinator.zoomedOutView!.frame, -offset.x, -offset.y)
    }
    
    // MARK: Actions
    
    @IBAction func dismissToMonths(sender :UIStoryboardSegue) {
        // TODO: Auto-unwinding currently not supported in tandem with iOS7 Transition API.
        if let indexPath = self.currentIndexPath {
            self.setUpTransitionForCellAtIndexPath(indexPath)
            self.transitionCoordinator.zoomReversed = true
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    @IBAction func requestAddingEvent(sender :AnyObject?) {
        if let recognizer = sender as? UITapGestureRecognizer {
            if recognizer == self.backgroundTapRecognizer {
                //NSLog("Background tap.");
                let delay = Int64(0.1 * Double(NSEC_PER_SEC))
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue()) {
                    self.toggleBackgroundViewHighlighted(false)
                    self.performSegueWithIdentifier(ETSegueAddDay, sender: sender)
                }
            }
        }
        
    }
    
    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if let navigationController = segue.destinationViewController as? NavigationController {
            self.setUpTransitionForCellAtIndexPath(self.currentIndexPath!)
            navigationController.transitioningDelegate = self.transitionCoordinator as UIViewControllerTransitioningDelegate
            navigationController.modalPresentationStyle = UIModalPresentationStyle.Custom
            if segue.identifier == ETSegueShowDay {
                if let viewController = navigationController.viewControllers[0] as? DayViewController {
                    let indexPaths = self.collectionView.indexPathsForSelectedItems() as [NSIndexPath]
                    if indexPaths.isEmpty { return }
                    let indexPath = indexPaths[0]
                    viewController.dayDate = self.dayDateAtIndexPath(indexPath)
                    viewController.dayEvents = self.dayEventsAtIndexPath(indexPath)
                }
            }
        }
        switch segue.identifier {
        case ETSegueAddDay:
            if let viewController = segue.destinationViewController as? EventViewController {
            }
        default:
            break
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String!, sender: AnyObject!) -> Bool {
        return true
    }
    
}

extension MonthsViewController: UIScrollViewDelegate { // MARK: Title View
    
    private func updateTitleView() {
        var titleText: String!
        let isInitialized = self.titleView.text == "Label"
        if self.allMonthDates?.isEmpty {
            // Default to app title.
            titleText = NSBundle.mainBundle().infoDictionary["CFBundleDisplayName"]! as String
            NSLog("INFO: Default title '%@'", titleText)
        } else if let index = self.currentSectionIndex {
            if let monthDate = self.allMonthDates?[index] {
                // Show month name.
                titleText = self.monthFormatter.stringFromDate(monthDate)
            }
        }
        self.titleView.setText(titleText.uppercaseString, animated: isInitialized)
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView!) {
        super.scrollViewDidScroll(scrollView)
        if let dataSource = self.dataSource {
            //NSLog("Offset: %@", NSStringFromCGPoint(scrollView.contentOffset))
            let direction = (scrollView.contentOffset.y < self.previousContentOffset.y) ? -1 : 1 // TODO: Represent as enum.
            self.previousContentOffset = scrollView.contentOffset
            var offset = scrollView.contentOffset.y
            if self.navigationController.navigationBar.translucent { // FIXME: UIKit omission that will(?) be addressed.
                offset += self.viewportYOffset
            }
            if let currentIndex = self.currentSectionIndex {
                let layout = self.collectionViewLayout
                switch direction {
                case -1:
                    let previousIndex = currentIndex - 1
                    let cellFrame = layout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader,
                        atIndexPath: NSIndexPath(forItem: 0, inSection: currentIndex)).frame
                    let top = cellFrame.origin.y
                    offset -= cellFrame.size.height / 2.0
                    if offset < top {
                        self.currentSectionIndex = previousIndex
                    }
                case 1:
                    let nextIndex = currentIndex + 1
                    let cellFrame = layout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader,
                        atIndexPath: NSIndexPath(forItem: 0, inSection: nextIndex)).frame
                    let bottom = cellFrame.origin.y + cellFrame.size.height
                    offset += cellFrame.size.height / 2.0
                    if offset > bottom {
                        self.currentSectionIndex = nextIndex
                    }
                default:
                    fatalError("Unsupported direction.")
                }
            }
        }
    }
    
}

extension MonthsViewController: UIGestureRecognizerDelegate, UIScrollViewDelegate { // MARK: Add Event
    
    private func setUpBackgroundView() {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        view.userInteractionEnabled = true
        view.addGestureRecognizer(self.backgroundTapRecognizer)
        self.collectionView.backgroundView = view
        self.originalBackgroundColor = view.backgroundColor
    }

    private func toggleBackgroundViewHighlighted(highlighted: Bool) {
        let backgroundView = self.collectionView.backgroundView
        backgroundView.backgroundColor = highlighted ? self.highlightedBackgroundColor : self.originalBackgroundColor
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldReceiveTouch touch: UITouch!) -> Bool {
        if gestureRecognizer == self.backgroundTapRecognizer {
            self.toggleBackgroundViewHighlighted(true)
            //NSLog("Begin possible background tap.")
        }
        return true
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewWillEndDragging(scrollView: UIScrollView!, withVelocity velocity: CGPoint, targetContentOffset: UnsafePointer<CGPoint>) {
        self.toggleBackgroundViewHighlighted(false)
    }
    
}

extension MonthsViewController: UICollectionViewDataSource {
    
    private func allDateDatesForMonthAtIndex(index: Int) -> [NSDate]? {
        if let dataSource = self.dataSource {
            if let monthsDays = dataSource[ETEntityCollectionDaysKey]! as? [Dictionary<String, [AnyObject]>] {
                if monthsDays.count > index {
                    let days = monthsDays[index] as Dictionary<String, [AnyObject]>
                    return days[ETEntityCollectionDatesKey]! as? [NSDate]
                }
            }
        }
        return nil
    }
    private func dayDateAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        if let dataSource = self.dataSource {
            if let monthsDays = dataSource[ETEntityCollectionDaysKey]! as? [Dictionary<String, [AnyObject]>] {
                let days = monthsDays[indexPath.section] as Dictionary<String, [AnyObject]>
                let daysDates = days[ETEntityCollectionDatesKey]! as [NSDate]
                return daysDates[indexPath.item]
            }
        }
        return nil
    }
    private func dayEventsAtIndexPath(indexPath: NSIndexPath) -> [EKEvent]? {
        if let dataSource = self.dataSource {
            if let monthsDays = dataSource[ETEntityCollectionDaysKey]! as? [Dictionary<String, [AnyObject]>] {
                let days = monthsDays[indexPath.section] as Dictionary<String, [AnyObject]>
                let daysEvents = days[ETEntityCollectionEventsKey]! as [[EKEvent]]
                return daysEvents[indexPath.item]
            }
        }
        return nil
    }

    // MARK: UICollectionViewDataSource
    
    override func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
        var number = 0
        if let monthDays = self.allDateDatesForMonthAtIndex(section) {
            number = monthDays.count
        }
        return number
    }
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int {
        var number = 0
        if let months = self.allMonthDates {
            number = months.count
        }
        return number
    }
    
    override func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellReuseIdentifier, forIndexPath: indexPath) as? DayViewCell {
            cell.setAccessibilityLabelsWithIndexPath(indexPath)
            for subview in cell.subviews as [UIView] {
                subview.hidden = false
            }
            if let dayDate = self.dayDateAtIndexPath(indexPath) {
                if let dayEvents = self.dayEventsAtIndexPath(indexPath) {
                    cell.isToday = dayDate.isEqualToDate(self.currentDayDate)
                    cell.dayText = self.dayFormatter.stringFromDate(dayDate)
                    cell.numberOfEvents = dayEvents.count
                    cell.borderInsets = self.borderInsetsForCell(cell, atIndexPath: indexPath)
                }
            }
            return cell
        }
        return nil
    }
    override func collectionView(collectionView: UICollectionView!, viewForSupplementaryElementOfKind kind: String!, atIndexPath indexPath: NSIndexPath!) -> UICollectionReusableView! {
        switch kind! {
        case UICollectionElementKindSectionHeader:
            if let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: HeaderReuseIdentifier, forIndexPath: indexPath) as? MonthHeaderView {
                if let months = self.allMonthDates {
                    let monthDate = months[indexPath.section]
                    headerView.monthName = self.monthFormatter.stringFromDate(monthDate)
                }
                return headerView
            }
        default:
            break
        }
        return nil
    }
    
}

extension MonthsViewController: UICollectionViewDelegate { // MARK: Day Cell
    
    private func borderInsetsForCell(cell: DayViewCell, atIndexPath indexPath:NSIndexPath) -> UIEdgeInsets {
        var borderInsets = cell.defaultBorderInsets
        
        let itemIndex = indexPath.item
        let itemCount = self.collectionView(self.collectionView, numberOfItemsInSection: indexPath.section)
        let lastItemIndex = itemCount - 1
        let lastRowItemIndex = self.numberOfColumns - 1
        let bottomEdgeStartIndex = lastItemIndex - self.numberOfColumns
        let rowItemIndex = itemIndex % self.numberOfColumns
        let remainingRowItemCount = lastRowItemIndex - rowItemIndex
        
        let isBottomEdgeCell = itemIndex > bottomEdgeStartIndex
        let isOnPartialLastRow = itemIndex + remainingRowItemCount >= lastItemIndex
        let isOnRowWithBottomEdgeCell = !isBottomEdgeCell && (itemIndex + remainingRowItemCount > bottomEdgeStartIndex)
        let isSingleRowCell = itemCount <= self.numberOfColumns
        let isTopEdgeCell = itemIndex < self.numberOfColumns
        
        if rowItemIndex == lastRowItemIndex {
            borderInsets.right = 0.0
        }
        if isBottomEdgeCell || isOnRowWithBottomEdgeCell || (isTopEdgeCell && isSingleRowCell) {
            borderInsets.bottom = 1.0
        }
        if isOnPartialLastRow && !isOnRowWithBottomEdgeCell && !isSingleRowCell {
            borderInsets.top = 0.0
        }
        
        return borderInsets
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView!, shouldSelectItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        self.currentIndexPath = indexPath
        let cell = self.collectionView.cellForItemAtIndexPath(indexPath) as DayViewCell
        cell.innerContentView.transform = CGAffineTransformMakeScale(0.98, 0.98)
        UIView.animateWithDuration( 0.3, delay: 0.0,
            usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { () in cell.innerContentView.transform = CGAffineTransformIdentity },
            completion: nil
        )
        return true
    }
    
}

extension MonthsViewController: UICollectionViewDelegateFlowLayout {

    private func updateMeasures() {
        // Cell size.
        self.numberOfColumns = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 2 : 3
        let numberOfGutters = self.numberOfColumns - 1
        let dimension = self.view.frame.size.width - CGFloat(numberOfGutters) * self.DayGutter
        self.cellSize = CGSize(width: dimension, height: dimension)
        // Misc.
        self.viewportYOffset = UIApplication.sharedApplication().statusBarFrame.size.height +
            self.navigationController.navigationBar.frame.size.height
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return DayGutter
    }
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return DayGutter
    }
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: MonthGutter, right: 0.0)
    }
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        return self.cellSize
    }
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return (section == 0) ? CGSizeZero : (collectionViewLayout as UICollectionViewFlowLayout).headerReferenceSize
    }

}