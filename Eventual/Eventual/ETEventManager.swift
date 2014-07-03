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

typealias ETFetchEventsCompletionHandler = () -> Void

@objc(ETEventManager) class EventManager: NSObject {
    
    var store: EKEventStore!
    var operationQueue: NSOperationQueue!
    
    var calendars: EKCalendar[]?
    var calendar:EKCalendar?
    
    var events: EKEvent[]?
    
    @lazy var eventsByMonthsAndDays: Dictionary<String, AnyObject[]> = {
        var months: Dictionary<String, AnyObject[]> = [:]
        var monthsDates: NSDate[] = []
        var monthsDays: Dictionary<String, AnyObject[]>[] = []
        let calendar = NSCalendar.currentCalendar()
        for event in self.events! {
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
        return months
    }()
    
    init() {
        super.init()
        self.store = EKEventStore()
        self.operationQueue = NSOperationQueue()
    }
    
    func completeSetup() {
        self.store.requestAccessToEntityType(EKEntityTypeEvent, completion: { (granted: Bool, accessError: NSError!) -> Void in
            var userInfo: Dictionary<String, AnyObject> = [:]
            userInfo[ETEntityAccessRequestNotificationTypeKey] = EKEntityTypeEvent
            if granted {
                userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationGranted
                self.calendars = self.store.calendarsForEntityType(EKEntityTypeEvent) as? EKCalendar[]
                self.calendar = self.store.defaultCalendarForNewEvents
            } else if !granted {
                userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationDenied
            } else if accessError {
                userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationError
                userInfo[ETEntityAccessRequestNotificationErrorKey] = accessError
            }
            NSNotificationCenter.defaultCenter()
                .postNotificationName(ETEntityAccessRequestNotification, object: self, userInfo: userInfo)
        })
    }
    
    func fetchEventsFromDate(startDate: NSDate = NSDate.date(),
                             untilDate endDate: NSDate,
                             completion: ETFetchEventsCompletionHandler) -> NSOperation {
        let predicate = self.store.predicateForCompletedRemindersWithCompletionDateStarting(
            startDate, ending: endDate, calendars: self.calendars)
        let fetchOperation = NSBlockOperation({ () -> Void in
            self.events = self.store.eventsMatchingPredicate(predicate) as? EKEvent[]
        })
        fetchOperation.queuePriority = NSOperationQueuePriority.VeryHigh
        let completionOperation = NSBlockOperation(completion)
        completionOperation.addDependency(fetchOperation)
        self.operationQueue.addOperation(fetchOperation)
        NSOperationQueue.mainQueue().addOperation(completionOperation)
        return fetchOperation
    }
    
    func saveEvent(event: EKEvent, error: NSErrorPointer) -> Bool {
        if !self.validateEvent(event, error: error) { return false }
        var didSave = self.store.saveEvent(event, span: EKSpanThisEvent, commit: true, error: error)
        if didSave {
            self._addEvent(event)
            var userInfo: Dictionary<String, AnyObject> = [:]
            userInfo[ETEntityOperationNotificationTypeKey] = EKEntityTypeEvent
            userInfo[ETEntityOperationNotificationDataKey] = event
            NSNotificationCenter.defaultCenter()
                .postNotificationName(ETEntitySaveOperationNotification, object: self, userInfo: userInfo)
        }
        return didSave
    }
    
    func validateEvent(event: EKEvent, error: NSErrorPointer) -> Bool {
        // TODO
        return true
    }
    
    func _addEvent(event: EKEvent) -> Bool {
        var didAdd = false
        if var events = self.events {
            let bridgedEvents = events.bridgeToObjectiveC()
            if bridgedEvents.containsObject(event) {
                events.append(event)
                bridgedEvents.sortedArrayUsingSelector(Selector("compareStartDateWithEvent:"))
                didAdd = true
            }
        }
        return didAdd
    }

}
