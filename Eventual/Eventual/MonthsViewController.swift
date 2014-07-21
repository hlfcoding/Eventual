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
    
    // MARK: Properties
    
    // TODO: Make class constants when possible.
    let _DayGutter: Float = 0.0
    let _MonthGutter: Float = 50.0
    
    var _currentDate: NSDate = NSDate.date()
    @lazy var _currentDayDate: NSDate = {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(
            calendar.components(.DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit, fromDate: self._currentDate)
        )
    }()
    var _currentIndexPath: NSIndexPath?
    var _currentSectionIndex: Int?
    
    var _cellSize: CGSize!
    var _numberOfColumns: Int!
    var _previousContentOffset: CGPoint!
    var _viewportYOffset: Float!
    
    @lazy var _dayFormatter: NSDateFormatter! = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    @lazy var _monthFormatter: NSDateFormatter! = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    @lazy var _transitionCoordinator: ZoomTransitionCoordinator! = {
        return ZoomTransitionCoordinator()
    }()
    
    @IBOutlet weak var _backgroundTapRecognizer: UITapGestureRecognizer! // Aspect(s): Add-Event.
    @IBOutlet weak var _titleView: NavigationTitleView!
    
    @lazy weak var _eventManager: EventManager! = {
        return EventManager.defaultManager()
    }()
    
    var _dataSource: ETEventByMonthAndDayCollection? {
        return self._eventManager.eventsByMonthsAndDays
    }
    
    var _allMonthDates: NSDate[]? {
        return self._dataSource!.bridgeToObjectiveC()[ETEntityCollectionDatesKey] as? NSDate[]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self._dayFormatter = nil
        self._monthFormatter = nil
        self._eventManager = nil
        self._transitionCoordinator = nil
    }
    
    // MARK: Initializers
    
    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        self._setUp()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    init(coder aDecoder: NSCoder!) {
        self._setUp()
        super.init(coder: aDecoder)
    }
    
    deinit {
        self._tearDown()
    }
    
    func _setUp() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: Selector("_eventAccessRequestDidComplete:"), name: ETEntityAccessRequestNotification, object: nil)
        center.addObserver(self, selector: Selector("_eventSaveOperationDidComplete:"), name: ETEntitySaveOperationNotification, object: nil)
    }
    func _tearDown() {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self._setAccessibilityLabels()
        self._setUpBackgroundView()
        self._updateMeasures()
    }
    
    func _setAccessibilityLabels() {
        self.collectionView.accessibilityLabel = ETLabelMonthDays // TODO: NSLocalizedString broken.
        self.collectionView.isAccessibilityElement = true
    }
    func _setUpBackgroundView() {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        view.userInteractionEnabled = true
        self.collectionView.backgroundView = view
    }
    func _updateMeasures() {
        // Cell size.
        self._numberOfColumns = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 2 : 3
        let numberOfGutters = self._numberOfColumns - 1
        var dimension = self.view.frame.size.width - Float(numberOfGutters) * self._DayGutter
        self._cellSize = CGSize(width: dimension, height: dimension)
        // Misc.
        self._viewportYOffset = UIApplication.sharedApplication().statusBarFrame.size.height +
            self.navigationController.navigationBar.frame.size.height
    }
    
    // MARK: Handlers
    
    func _eventAccessRequestDidComplete(notification: NSNotification) {
        let result: String = notification.userInfo[ETEntityAccessRequestNotificationResultKey] as String
        switch result {
        case ETEntityAccessRequestNotificationGranted:
            let components = NSDateComponents()
            components.year = 1
            let endDate: NSDate = NSCalendar.currentCalendar().dateByAddingComponents(
                components, toDate: self._currentDate, options: NSCalendarOptions.fromMask(0))
            let operation: NSOperation = self._eventManager.fetchEventsFromDate(untilDate: endDate) {
                //NSLog("Events: %@", self._eventManager.eventsByMonthsAndDays!)
                self.collectionView.reloadData()
                self._updateTitleView()
            }
        }
    }
    
    func _eventSaveOperationDidComplete(notification: NSNotification) {
        let type: EKEntityType = notification.userInfo[ETEntityOperationNotificationTypeKey] as EKEntityType
        switch type {
        case EKEntityTypeEvent:
            let event: EKEvent = notification.userInfo[ETEntityOperationNotificationDataKey] as EKEvent
            self._eventManager.invalidateDerivedCollections()
            self.collectionView.reloadData()
        }
    }
    
}

extension MonthsViewController { // MARK: Title View
    
    func _updateTitleView() {
        
    }
    
}

extension MonthsViewController: UICollectionViewDataSource {
    
    // MARK: Helpers
    
    func _allDateDatesForMonthAtIndex(index: Int) -> NSDate[]? {
        if let monthsDays = self._dataSource!.bridgeToObjectiveC()[ETEntityCollectionDaysKey] as? Dictionary<String, AnyObject[]>[] {
            if monthsDays.count > index {
                let days = monthsDays[index] as Dictionary<String, AnyObject[]>
                return days.bridgeToObjectiveC()[ETEntityCollectionDatesKey] as? NSDate[]
            }
        }
        return nil
    }
    func _dayDateAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        if let monthsDays = self._dataSource!.bridgeToObjectiveC()[ETEntityCollectionDaysKey] as? Dictionary<String, AnyObject[]>[] {
            let days = monthsDays[indexPath.section] as Dictionary<String, AnyObject[]>
            let daysDates = days.bridgeToObjectiveC()[ETEntityCollectionDatesKey] as NSDate[]
            return daysDates[indexPath.item]
        }
        return nil
    }
    func _dayEventsAtIndexPath(indexPath: NSIndexPath) -> EKEvent[]? {
        if let monthsDays = self._dataSource!.bridgeToObjectiveC()[ETEntityCollectionDaysKey] as? Dictionary<String, AnyObject[]>[] {
            let days = monthsDays[indexPath.section] as Dictionary<String, AnyObject[]>
            let daysEvents = days.bridgeToObjectiveC()[ETEntityCollectionEventsKey] as EKEvent[][]
            return daysEvents[indexPath.item]
        }
        return nil
    }
    
}

extension MonthsViewController: UICollectionViewDelegate {
    
}

extension MonthsViewController: UICollectionViewDelegateFlowLayout {
    
}

extension MonthsViewController: UIGestureRecognizerDelegate {
    
}
