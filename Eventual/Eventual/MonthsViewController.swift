//
//  ETMonthsViewController.swift
//  Eventual
//
//  Created by Nest Master on 6/2/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit
import EventKit

@objc(ETMonthsViewController) class MonthsViewController: UIViewController,
    // Private
    UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    // TODO: Make class constants when possible.
    let _DayGutter = 0.0
    let _MonthGutter = 50.0
    
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
    
    @lazy var _dayFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    @lazy var _monthFormatter: NSDateFormatter = {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

