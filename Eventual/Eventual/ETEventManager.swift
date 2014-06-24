//
//  ETEventManager.swift
//  Eventual
//
//  Created by Nest Master on 6/2/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit
import EventKit

let ETEntityAccessRequestNotification = "ETEntityAccess"

let ETEntityAccessRequestNotificationDenied = "ETEntityAccessDenied"
let ETEntityAccessRequestNotificationError = "ETEntityAccessError"
let ETEntityAccessRequestNotificationGranted = "ETEntityAccessGranted"

let ETEntityAccessRequestNotificationErrorKey = "ETEntityAccessErrorKey"
let ETEntityAccessRequestNotificationResultKey = "ETEntityAccessResultKey"
let ETEntityAccessRequestNotificationTypeKey = "ETEntityAccessTypeKey"

let ETEntitySaveOperationNotification = "ETEntitySaveOperation"
let ETEntityOperationNotificationTypeKey = "ETEntityOperationTypeKey"
let ETEntityOperationNotificationDataKey = "ETEntityOperationDataKey"

let ETEntityCollectionDatesKey = "dates"
let ETEntityCollectionDaysKey = "days"
let ETEntityCollectionEventsKey = "events"

@objc(ETEventManager) class EventManager: NSObject {
    
    var _mutableEvents: EKEvent[] = []
    var events: EKEvent[] {
    return self._mutableEvents
    }
    
    @lazy var eventsByMonthsAndDays: Dictionary<String, AnyObject[]> = {
        var months: Dictionary<String, AnyObject[]> = [:]
        var monthsDates: NSDate[] = []
        var monthsDays: Dictionary<String, AnyObject[]>[] = []
        let calendar = NSCalendar.currentCalendar()
        for event in self.events {
            let monthComponents = calendar.components(.CalendarUnitMonth | .YearCalendarUnit, fromDate: event.startDate)
            let dayComponents = calendar.components(.DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit, fromDate: event.startDate)
            let monthDate = calendar.dateFromComponents(monthComponents)
            let dayDate = calendar.dateFromComponents(dayComponents)
            let monthIndex :Int = monthsDates.bridgeToObjectiveC().indexOfObject(monthDate)
            var days :Dictionary<String, AnyObject[]>
            var daysDates :NSDate[]
            var daysEvents :EKEvent[][]
            var dayEvents :EKEvent[]
            if monthIndex == NSNotFound {
                monthsDates.append(monthDate)
                days = [:]
                daysDates = []
                daysEvents = []
                days[ETEntityCollectionDatesKey] = daysDates as NSDate[]
                days[ETEntityCollectionEventsKey] = daysEvents as AnyObject[]
                monthsDays.append(days)
            } else {
                days = monthsDays[monthIndex]
                daysDates = days.bridgeToObjectiveC()[ETEntityCollectionDatesKey] as NSDate[]
                daysEvents = days.bridgeToObjectiveC()[ETEntityCollectionEventsKey] as EKEvent[][]
            }
            let dayIndex = daysDates.bridgeToObjectiveC().indexOfObject(dayDate)
            if dayIndex == NSNotFound {
                daysDates.append(dayDate)
                dayEvents = []
                daysEvents.append(dayEvents)
            } else {
                dayEvents = daysEvents[dayIndex]
            }
            dayEvents.append(event)
        }
        months[ETEntityCollectionDatesKey] = monthsDates
        months[ETEntityCollectionDaysKey] = monthsDays
        return months;
    }()
    
    init() {
        super.init()
    }
   
}
