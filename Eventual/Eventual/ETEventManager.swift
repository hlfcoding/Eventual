//
//  ETEventManager.swift
//  Eventual
//
//  Created by Nest Master on 6/2/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit
import EventKit

var ETEntityAccessRequestNotification = "ETEntityAccess"

var ETEntityAccessRequestNotificationDenied = "ETEntityAccessDenied"
var ETEntityAccessRequestNotificationError = "ETEntityAccessError"
var ETEntityAccessRequestNotificationGranted = "ETEntityAccessGranted"

var ETEntityAccessRequestNotificationErrorKey = "ETEntityAccessErrorKey"
var ETEntityAccessRequestNotificationResultKey = "ETEntityAccessResultKey"
var ETEntityAccessRequestNotificationTypeKey = "ETEntityAccessTypeKey"

var ETEntitySaveOperationNotification = "ETEntitySaveOperation"
var ETEntityOperationNotificationTypeKey = "ETEntityOperationTypeKey"
var ETEntityOperationNotificationDataKey = "ETEntityOperationDataKey"

var ETEntityCollectionDatesKey = "dates"
var ETEntityCollectionDaysKey = "days"
var ETEntityCollectionEventsKey = "events"

class ETEventManager: NSObject {
    
    var _mutableEvents: NSMutableArray = []
    var events: NSArray {
    return self._mutableEvents
    }
    
    var _eventsByMonthsAndDays: NSDictionary?
    var eventsByMonthsAndDays: NSDictionary {
    if !self._eventsByMonthsAndDays {
        var months: NSMutableDictionary = NSMutableDictionary.dictionary()
        var monthsDates: NSMutableArray = []
        var monthsDays: NSMutableArray = []
        let calendar: NSCalendar = NSCalendar.currentCalendar()
        for event :AnyObject in self.events {
            let monthComponents: NSDateComponents = calendar.components(
                NSCalendarUnit.CalendarUnitMonth|NSCalendarUnit.YearCalendarUnit,
                fromDate: event.startDate)
            let dayComponents: NSDateComponents = calendar.components(
                NSCalendarUnit.DayCalendarUnit|NSCalendarUnit.MonthCalendarUnit|NSCalendarUnit.YearCalendarUnit,
                fromDate: event.startDate)
            let monthDate :NSDate = calendar.dateFromComponents(monthComponents)
            let dayDate :NSDate = calendar.dateFromComponents(dayComponents)
            let monthIndex :Int = monthsDates.indexOfObject(monthDate)
            var days :NSMutableDictionary
            var daysDates :NSMutableArray
            var daysEvents :NSMutableArray
            var dayEvents :NSMutableArray
            if monthIndex == NSNotFound {
                monthsDates.addObject(monthDate)
                days = NSMutableDictionary.dictionary()
                daysDates = []
                daysEvents = []
                days[ETEntityCollectionDatesKey] = daysDates
                days[ETEntityCollectionEventsKey] = daysEvents
                monthsDays.addObject(days)
            } else {
                days = monthsDays[monthIndex] as NSMutableDictionary
                daysDates = days[ETEntityCollectionDatesKey] as NSMutableArray
                daysEvents = days[ETEntityCollectionEventsKey] as NSMutableArray
            }
            let dayIndex = daysDates.indexOfObject(dayDate)
            if dayIndex == NSNotFound {
                daysDates.addObject(dayDate)
                dayEvents = []
                daysEvents.addObject(dayEvents)
            } else {
                dayEvents = daysEvents[dayIndex] as NSMutableArray
            }
            dayEvents.addObject(event)
        }
        months[ETEntityCollectionDatesKey] = monthsDates
        months[ETEntityCollectionDaysKey] = monthsDays
        self._eventsByMonthsAndDays = months;
    }
    return self._eventsByMonthsAndDays!
    }
    
    init() {
        super.init()
    }
   
}
