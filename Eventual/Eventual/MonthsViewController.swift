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
    private let DayGutter: CGFloat = 0.0
    private let MonthGutter: CGFloat = 50.0
    
    private var currentDate: NSDate = NSDate.date()
    private lazy var currentDayDate: NSDate = {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(
            calendar.components(.DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit, fromDate: self.currentDate)
        )
    }()
    private var currentIndexPath: NSIndexPath?
    private var currentSectionIndex: Int?
    
    private var cellSize: CGSize!
    private var numberOfColumns: Int!
    private var previousContentOffset: CGPoint!
    private var viewportYOffset: CGFloat!
    
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
    
    private lazy var transitionCoordinator: ZoomTransitionCoordinator! = {
        return ZoomTransitionCoordinator()
    }()
    
    @IBOutlet private weak var backgroundTapRecognizer: UITapGestureRecognizer! // Aspect(s): Add-Event.
    @IBOutlet private weak var titleView: NavigationTitleView!
    
    private lazy var eventManager: EventManager! = {
        return EventManager.defaultManager()
    }()
    
    private var dataSource: ETEventByMonthAndDayCollection? {
        return self.eventManager.eventsByMonthsAndDays
    }
    
    private var allMonthDates: [NSDate]? {
        return self.dataSource!.bridgeToObjectiveC()[ETEntityCollectionDatesKey] as? [NSDate]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.dayFormatter = nil
        self.monthFormatter = nil
        self.eventManager = nil
        self.transitionCoordinator = nil
    }
    
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
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
        self.updateMeasures()
    }
    
    private func setAccessibilityLabels() {
        self.collectionView.accessibilityLabel = ETLabelMonthDays // TODO: NSLocalizedString broken.
        self.collectionView.isAccessibilityElement = true
    }
    private func setUpBackgroundView() {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        view.userInteractionEnabled = true
        self.collectionView.backgroundView = view
    }
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
    
    // MARK: Handlers
    
    private func eventAccessRequestDidComplete(notification: NSNotification) {
        let result: String = notification.userInfo.bridgeToObjectiveC()[ETEntityAccessRequestNotificationResultKey] as String
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
        let type: EKEntityType = notification.userInfo.bridgeToObjectiveC()[ETEntityOperationNotificationTypeKey] as EKEntityType
        switch type {
        case EKEntityTypeEvent:
            let event: EKEvent = notification.userInfo[ETEntityOperationNotificationDataKey] as EKEvent
            self.eventManager.invalidateDerivedCollections()
            self.collectionView.reloadData()
        default:
            fatalError("Unimplemented entity type.")
        }
    }
    
}

extension MonthsViewController { // MARK: Title View
    
    private func updateTitleView() {
        
    }
    
}

extension MonthsViewController: UICollectionViewDataSource {
    
    // MARK: Helpers
    
    private func allDateDatesForMonthAtIndex(index: Int) -> [NSDate]? {
        if let monthsDays = self.dataSource!.bridgeToObjectiveC()[ETEntityCollectionDaysKey] as? [Dictionary<String, [AnyObject]>] {
            if monthsDays.count > index {
                let days = monthsDays[index] as Dictionary<String, [AnyObject]>
                return days.bridgeToObjectiveC()[ETEntityCollectionDatesKey] as? [NSDate]
            }
        }
        return nil
    }
    private func dayDateAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        if let monthsDays = self.dataSource!.bridgeToObjectiveC()[ETEntityCollectionDaysKey] as? [Dictionary<String, [AnyObject]>] {
            let days = monthsDays[indexPath.section] as Dictionary<String, [AnyObject]>
            let daysDates = days.bridgeToObjectiveC()[ETEntityCollectionDatesKey] as [NSDate]
            return daysDates[indexPath.item]
        }
        return nil
    }
    private func dayEventsAtIndexPath(indexPath: NSIndexPath) -> [EKEvent]? {
        if let monthsDays = self.dataSource!.bridgeToObjectiveC()[ETEntityCollectionDaysKey] as? [Dictionary<String, [AnyObject]>] {
            let days = monthsDays[indexPath.section] as Dictionary<String, [AnyObject]>
            let daysEvents = days.bridgeToObjectiveC()[ETEntityCollectionEventsKey] as [[EKEvent]]
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
