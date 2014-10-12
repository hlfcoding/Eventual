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
        )!
    }()
    private var currentIndexPath: NSIndexPath?
    private var currentSectionIndex: Int = 0 {
        didSet {
            if self.currentSectionIndex == oldValue { return }
            self.updateTitleView()
        }
    }
    
    // MARK: Add Event
    
    @IBOutlet private var backgroundTapRecognizer: UITapGestureRecognizer!
    @IBOutlet private var titleView: NavigationTitleView!
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
    
    private var tileLayout: CollectionViewTileLayout {
        return self.collectionViewLayout as CollectionViewTileLayout
    }
    
    // MARK: Navigation
    
    private lazy var transitionCoordinator: ZoomTransitionCoordinator! = {
        return ZoomTransitionCoordinator()
    }()
    
    // MARK: Title View
    
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
        self.setUpBackgroundView()
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
        self.collectionView!.reloadData()
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
                self.updateTitleView()
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
    
    // TODO: Unwind segues don't work. This may require re-architecting.
    @IBAction private func dismissToMonths(sender: UIStoryboardSegue) {
        // TODO: Auto-unwinding currently not supported in tandem with iOS7 Transition API.
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
                    self.toggleBackgroundViewHighlighted(false)
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
            if let viewController = segue.destinationViewController as? EventViewController {
            }
        default: break
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
}

// MARK: - Title View

enum ETScrollDirection {
    case Top, Left, Bottom, Right
}

extension MonthsViewController: UIScrollViewDelegate {
    
    // TODO: Don't use the cheap animation. Animate it interactively with the scroll.
    private func updateTitleView() {
        var titleText: String!
        let isInitialized = self.titleView.text != "Label"
        if self.allMonthDates == nil || self.allMonthDates!.isEmpty {
            // Default to app title.
            let info = NSBundle.mainBundle().infoDictionary
            titleText = (info["CFBundleDisplayName"]? ?? info["CFBundleName"]!) as String
            NSLog("INFO: Default title '%@'", titleText)
        } else {
            if let monthDate = self.allMonthDates?[self.currentSectionIndex] {
                // Show month name.
                titleText = self.monthFormatter.stringFromDate(monthDate)
            }
        }
        self.titleView.setText(titleText.uppercaseString, animated: isInitialized)
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if let dataSource = self.dataSource {
            //NSLog("Offset: %@", NSStringFromCGPoint(scrollView.contentOffset))
            let direction: ETScrollDirection = (self.previousContentOffset != nil && scrollView.contentOffset.y < self.previousContentOffset.y)
                                               ? .Top : .Bottom
            self.previousContentOffset = scrollView.contentOffset
            var offset = scrollView.contentOffset.y
            if self.navigationController!.navigationBar.translucent { // FIXME: UIKit omission that will(?) be addressed.
                offset += self.tileLayout.viewportYOffset
            }
            let currentIndex = self.currentSectionIndex
            let layout = self.collectionViewLayout
            switch direction {
            case .Top:
                let previousIndex = currentIndex - 1
                if previousIndex < 0 { return }
                let cellFrame = layout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader,
                    atIndexPath: NSIndexPath(forItem: 0, inSection: currentIndex)).frame
                let top = cellFrame.origin.y
                offset -= cellFrame.size.height / 2.0
                if offset < top {
                    self.currentSectionIndex = previousIndex
                }
            case .Bottom:
                let nextIndex = currentIndex + 1
                if nextIndex >= self.collectionView!.numberOfSections() { return }
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

// MARK: - Add Event

extension MonthsViewController: UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    private func setUpBackgroundView() {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        view.userInteractionEnabled = true
        view.addGestureRecognizer(self.backgroundTapRecognizer)
        self.collectionView!.backgroundColor = self.appearanceManager.lightGrayColor
        self.collectionView!.backgroundView = view
        self.originalBackgroundColor = view.backgroundColor
    }

    private func toggleBackgroundViewHighlighted(highlighted: Bool) {
        let backgroundView = self.collectionView!.backgroundView!
        let backgroundColor = highlighted ? self.highlightedBackgroundColor : self.originalBackgroundColor
        UIView.animateWithDuration( 0.2, delay: 0.0,
            options: .CurveEaseInOut | .BeginFromCurrentState,
            animations: { backgroundView.backgroundColor = backgroundColor },
            completion: nil
        )
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldReceiveTouch touch: UITouch!) -> Bool {
        if gestureRecognizer === self.backgroundTapRecognizer {
            self.toggleBackgroundViewHighlighted(true)
            //NSLog("Begin possible background tap.")
        }
        return true
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint,
                  targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        self.toggleBackgroundViewHighlighted(false)
    }
    
}

// MARK: - Data

extension MonthsViewController: UICollectionViewDataSource {
    
    private func allDateDatesForMonthAtIndex(index: Int) -> [NSDate]? {
        if let dataSource = self.dataSource {
            if let monthsDays = dataSource[ETEntityCollectionDaysKey]! as? [[String: [AnyObject]]] {
                if monthsDays.count > index {
                    let days = monthsDays[index] as [String: [AnyObject]]
                    return days[ETEntityCollectionDatesKey]! as? [NSDate]
                }
            }
        }
        return nil
    }
    private func dayDateAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        if let dataSource = self.dataSource {
            if let monthsDays = dataSource[ETEntityCollectionDaysKey]! as? [[String: [AnyObject]]] {
                let days = monthsDays[indexPath.section] as [String: [AnyObject]]
                let daysDates = days[ETEntityCollectionDatesKey]! as [NSDate]
                return daysDates[indexPath.item]
            }
        }
        return nil
    }
    private func dayEventsAtIndexPath(indexPath: NSIndexPath) -> [EKEvent]? {
        if let dataSource = self.dataSource {
            if let monthsDays = dataSource[ETEntityCollectionDaysKey]! as? [[String: [AnyObject]]] {
                let days = monthsDays[indexPath.section] as [String: [AnyObject]]
                let daysEvents = days[ETEntityCollectionEventsKey]! as [[EKEvent]]
                return daysEvents[indexPath.item]
            }
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
        cell.backgroundColor = self.appearanceManager.blueColor
        for subview in cell.subviews as [UIView] {
            subview.hidden = false
        }
        if let dayDate = self.dayDateAtIndexPath(indexPath) {
            if let dayEvents = self.dayEventsAtIndexPath(indexPath) {
                cell.isToday = dayDate.isEqualToDate(self.currentDayDate)
                cell.dayText = self.dayFormatter.stringFromDate(dayDate)
                cell.numberOfEvents = dayEvents.count
                cell.borderInsets = self.tileLayout.borderInsetsForDefaultBorderInsets(cell.defaultBorderInsets!,
                    numberOfSectionItems: collectionView.numberOfItemsInSection(indexPath.section),
                    atIndexPath: indexPath)
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
        let cell = self.collectionView!.cellForItemAtIndexPath(indexPath) as DayViewCell
        cell.innerContentView.transform = CGAffineTransformMakeScale(0.98, 0.98)
        UIView.animateWithDuration( 0.4, delay: 0.0,
            usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0,
            options: .CurveEaseInOut,
            animations: { cell.innerContentView.transform = CGAffineTransformIdentity },
            completion: nil
        )
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
                self.monthLabel.text = monthName.uppercaseString
            }
        }
    }
    
    @IBOutlet private var monthLabel: UILabel!
    
    override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
}