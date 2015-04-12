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
    
    private var dataSource: ETEventByMonthAndDayCollection? {
        return self.eventManager.eventsByMonthsAndDays
    }
    
    private var allMonthDates: [NSDate]? {
        if let dataSource = self.dataSource {
            return dataSource[ETEntityCollectionDatesKey] as! [NSDate]?
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
            name: ETEntitySaveOperationNotification, object: nil
        )
        center.addObserver( self,
            selector: Selector("eventAccessRequestDidComplete:"),
            name: ETEntityAccessRequestNotification, object: nil
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
        if let userInfo = notification.userInfo as? [String: AnyObject],
               result = userInfo[ETEntityAccessRequestNotificationResultKey] as? String
        {
            switch result {
            case ETEntityAccessRequestNotificationGranted:
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

    @IBAction private func requestAddingEvent(sender: AnyObject?) {
        if let recognizer = sender as? UITapGestureRecognizer where recognizer === self.backgroundTapRecognizer {
            //NSLog("Background tap.")
            dispatch_after(0.1) {
                self.interactiveBackgroundViewTrait.toggleHighlighted(false)
                self.performSegueWithIdentifier(ETSegue.AddEvent.rawValue, sender: sender)
            }
        }
    }
    
    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if let navigationController = segue.destinationViewController as? NavigationController,
               viewController = navigationController.topViewController as? DayViewController
               where segue.identifier == ETSegue.ShowDay.rawValue,
           let firstIndexPath = (self.collectionView!.indexPathsForSelectedItems() as? [NSIndexPath])?.first
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
        if let identifier = segue.identifier {
            switch identifier {
            case ETSegue.AddEvent.rawValue:
                self.currentIndexPath = nil // Reset.
            default: break
            }
        }
        super.prepareForSegue(segue, sender: sender)
    }

    // MARK: TransitionAnimationDelegate

    func animatedTransition(transition: AnimatedTransition,
         snapshotReferenceViewWhenReversed reversed: Bool) -> UIView
    {
        if let indexPath = self.currentIndexPath, cell = self.collectionView!.cellForItemAtIndexPath(indexPath) {
            return cell
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
    func beginInteractivePresentationTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)
    {
        if let cell = referenceView as? DayViewCell, indexPath = self.collectionView!.indexPathForCell(cell) {
            self.currentIndexPath = indexPath
            self.performSegueWithIdentifier(ETSegue.ShowDay.rawValue, sender: transition)
        }
    }

    func interactiveTransition(transition: InteractiveTransition,
         destinationScaleForSnapshotReferenceView referenceView: UIView?,
         contextView: UIView, reversed: Bool) -> CGFloat
    {
        if !reversed { return -1.0 }
        if let zoomTransition = transition as? InteractiveZoomTransition,
               indexPath = self.currentIndexPath, cell = self.collectionView!.cellForItemAtIndexPath(indexPath)
        {
            return cell.frame.size.width / zoomTransition.pinchSpan
        }
        return -1.0
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
                var headerLabelTop = self.cachedHeaderLabelTop
                if let collectionView = self.collectionView where headerLabelTop == nil,
                   let monthHeaderView = collectionView.dequeueReusableSupplementaryViewOfKind( headerKind,
                       withReuseIdentifier: MonthsViewController.HeaderReuseIdentifier, forIndexPath: indexPath) as? MonthHeaderView
                {
                    headerLabelTop = monthHeaderView.monthLabel.frame.origin.y
                }
                if let headerLabelTop = headerLabelTop {
                    self.cachedHeaderLabelTop = headerLabelTop
                    return headerLayoutAttributes.frame.origin.y + headerLabelTop
                }
            }
            return nil
        }
        var offset: CGFloat!
        var offsetChange: CGFloat!
        var index: Int!
        switch self.currentScrollDirection {
        case .Top:
            let previousIndex = currentIndex - 1
            if previousIndex < 0 { return }
            if let headerTop = headerTopForIndexPath(NSIndexPath(forItem: 0, inSection: currentIndex)) {
                offsetChange = titleTop - headerTop
                if titleBottom < headerTop {
                    offset = CGFloat(previousIndex) * titleHeight
                    index = previousIndex
                } else if titleTop < headerTop && abs(offsetChange) <= titleHeight {
                    offset = CGFloat(currentIndex) * titleHeight + offsetChange
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
                } else if titleBottom > headerTop && abs(offsetChange) <= titleHeight {
                    offset = CGFloat(currentIndex) * titleHeight + offsetChange
                }
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
    
    private var currentScrollDirection: ETScrollDirection {
        if let previousContentOffset = self.previousContentOffset
               where self.collectionView!.contentOffset.y < previousContentOffset.y
        { return .Top }
        return .Bottom
    }
    
    private var currentVisibleContentYOffset: CGFloat {
        let scrollView = self.collectionView!
        var offset = scrollView.contentOffset.y
        if (self.edgesForExtendedLayout.rawValue & UIRectEdge.Top.rawValue) != 0,
           let navigationController = self.navigationController
        {
            offset += self.tileLayout.viewportYOffset
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

extension MonthsViewController: UIGestureRecognizerDelegate, UIScrollViewDelegate {

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
        if let dataSource = self.dataSource,
               monthsDays = dataSource[ETEntityCollectionDaysKey] as? [NSDictionary]
               where monthsDays.count > index,
           let days = monthsDays[index] as? [String: [AnyObject]],
               allDates = days[ETEntityCollectionDatesKey] as? [NSDate]
        {
            return allDates
        }
        return nil
    }
    private func dayDateAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        if let dataSource = self.dataSource,
               monthsDays = dataSource[ETEntityCollectionDaysKey] as? [NSDictionary],
               days = monthsDays[indexPath.section] as? [String: [AnyObject]],
               daysDates = days[ETEntityCollectionDatesKey] as? [NSDate]
        {
            return daysDates[indexPath.item]
        }
        return nil
    }
    private func dayEventsAtIndexPath(indexPath: NSIndexPath) -> [EKEvent]? {
        if let dataSource = self.dataSource,
               monthsDays = dataSource[ETEntityCollectionDaysKey] as? [NSDictionary],
               days = monthsDays[indexPath.section] as? [String: [AnyObject]],
               daysEvents = days[ETEntityCollectionEventsKey] as? [[EKEvent]]
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(MonthsViewController.CellReuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
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
        let hiddenView = UICollectionReusableView(frame: CGRectZero)
        hiddenView.hidden = true
        switch kind {
        case UICollectionElementKindSectionHeader:
            if let headerView = collectionView.dequeueReusableSupplementaryViewOfKind( kind,
                   withReuseIdentifier: MonthsViewController.HeaderReuseIdentifier, forIndexPath: indexPath) as? MonthHeaderView,
                   monthDate = self.allMonthDates?[indexPath.section]
            {
                headerView.monthName = self.monthFormatter.stringFromDate(monthDate)
                headerView.monthLabel.textColor = self.appearanceManager.lightGrayTextColor
                return headerView
            }
        case UICollectionElementKindSectionFooter:
            fatalError("No footer supplementary view.")
        default:
            fatalError("Not implemented.")
        }
        return hiddenView
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

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
         referenceSizeForHeaderInSection section: Int) -> CGSize
    {
        if (section == 0) { return CGSizeZero }
        return (collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize ?? CGSizeZero
    }

}

// MARK: - Minor classes

@objc(ETMonthHeaderView) class MonthHeaderView: UICollectionReusableView {
    
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