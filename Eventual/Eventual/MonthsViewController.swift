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
    let DayGutter = 0.0
    let MonthGutter = 50.0
    
    var currentDate: NSDate = NSDate.date()
    @lazy var currentDayDate: NSDate = {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(
            calendar.components(.DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit, fromDate: self.currentDate)
        )
    }()
    var currentIndexPath: NSIndexPath?
    var currentSectionIndex: Int?
    
    var cellSize: CGSize!
    var numberOfColumns: Int!
    var previousContentOffset: CGPoint!
    var viewportYOffset: Float!
    
    @lazy var dayFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    @lazy var monthFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    var transitionCoordinator: ZoomTransitionCoordinator?
    
    @IBOutlet weak var backgroundTapRecognizer: UITapGestureRecognizer! // Aspect(s): Add-Event.
    @IBOutlet weak var titleView: NavigationTitleView!
    
    weak var eventManager: EventManager!
    
    var dataSource: ETEventByMonthAndDayCollection? {
        return self.eventManager.eventsByMonthsAndDays
    }
    
    var allMonthDates: NSDate[]? {
        return self.dataSource!.bridgeToObjectiveC()[ETEntityCollectionDatesKey] as? NSDate[]
    }
    
    func allDateDatesForMonthAtIndex(index: Int) -> NSDate[]? {
        if let monthsDays = self.dataSource!.bridgeToObjectiveC()[ETEntityCollectionDaysKey] as? Dictionary<String, AnyObject[]>[] {
            if monthsDays.count > index {
                let days = monthsDays[index] as Dictionary<String, AnyObject[]>
                return days.bridgeToObjectiveC()[ETEntityCollectionDatesKey] as? NSDate[]
            }
        }
        return nil
    }
    
    func dayDateAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        if let monthsDays = self.dataSource!.bridgeToObjectiveC()[ETEntityCollectionDaysKey] as? Dictionary<String, AnyObject[]>[] {
            let days = monthsDays[indexPath.section] as Dictionary<String, AnyObject[]>
            let daysDates = days.bridgeToObjectiveC()[ETEntityCollectionDatesKey] as NSDate[]
            return daysDates[indexPath.item]
        }
        return nil
    }

    func dayEventsAtIndexPath(indexPath: NSIndexPath) -> EKEvent[]? {
        if let monthsDays = self.dataSource!.bridgeToObjectiveC()[ETEntityCollectionDaysKey] as? Dictionary<String, AnyObject[]>[] {
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

