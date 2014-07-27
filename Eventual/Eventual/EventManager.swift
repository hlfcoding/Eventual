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
typealias ETEventByMonthAndDayCollection = Dictionary<String, [AnyObject]>

@objc(ETEventManager) class EventManager: NSObject {
    
    var store: EKEventStore!
    
    private var operationQueue: NSOperationQueue!
    
    private var calendars: [EKCalendar]?
    private var calendar:EKCalendar?
    
    var events: NSArray? { return self.mutableEvents }
    private var mutableEvents: [EKEvent]? {
    didSet {
        if self.mutableEvents! != oldValue! {
            self.invalidateEvents()
        }
    }
    }

    lazy var eventsByMonthsAndDays: ETEventByMonthAndDayCollection? = {
        if let events: [EKEvent] = self.events as? [EKEvent] {
            var months: Dictionary<String, [AnyObject]> = [:]
            var monthsDates: [NSDate] = []
            var monthsDays: [Dictionary<String, [AnyObject]>] = []
            let calendar = NSCalendar.currentCalendar()
            for event in events {
                let monthComponents = calendar.components(.CalendarUnitMonth | .YearCalendarUnit, fromDate: event.startDate)
                let dayComponents = calendar.components(.DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit, fromDate: event.startDate)
                let monthDate = calendar.dateFromComponents(monthComponents)
                let dayDate = calendar.dateFromComponents(dayComponents)
                let monthIndex :Int = monthsDates.bridgeToObjectiveC().indexOfObject(monthDate)
                var days :Dictionary<String, [AnyObject]>
                var daysDates :[NSDate]
                var daysEvents :[[EKEvent]]
                var dayEvents :[EKEvent]
                if monthIndex == NSNotFound {
                    monthsDates += monthDate
                    days = [:]
                    daysDates = []
                    daysEvents = []
                    days[ETEntityCollectionDatesKey] = daysDates as [NSDate]
                    days[ETEntityCollectionEventsKey] = daysEvents as [AnyObject]
                    monthsDays += days
                } else {
                    days = monthsDays[monthIndex]
                    daysDates = days[ETEntityCollectionDatesKey]! as [NSDate]
                    daysEvents = days[ETEntityCollectionEventsKey]! as [[EKEvent]]
                }
                let dayIndex = daysDates.bridgeToObjectiveC().indexOfObject(dayDate)
                if dayIndex == NSNotFound {
                    daysDates += dayDate
                    dayEvents = []
                    daysEvents += dayEvents
                } else {
                    dayEvents = daysEvents[dayIndex]
                }
                dayEvents += event
            }
            months[ETEntityCollectionDatesKey] = monthsDates
            months[ETEntityCollectionDaysKey] = monthsDays
            return months
        } else {
            return nil
        }
    }()
    private func invalidateEvents() -> Bool {
        var didInvalidate = false
        if let events = self.eventsByMonthsAndDays {
            self.eventsByMonthsAndDays = nil
            didInvalidate = true
        }
        return didInvalidate
    }
    func invalidateDerivedCollections() {
        self.eventsByMonthsAndDays = nil
    }
    
    init() {
        self.store = EKEventStore()
        self.operationQueue = NSOperationQueue()
        super.init()
    }

    func completeSetup() {
        self.store.requestAccessToEntityType(EKEntityTypeEvent, completion: { (granted: Bool, accessError: NSError!) -> Void in
            var userInfo: Dictionary<String, AnyObject> = [:]
            userInfo[ETEntityAccessRequestNotificationTypeKey] = EKEntityTypeEvent
            if granted {
                userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationGranted
                self.calendars = self.store.calendarsForEntityType(EKEntityTypeEvent) as? [EKCalendar]
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

    class func defaultManager() -> EventManager {
        return (UIApplication.sharedApplication().delegate as AppDelegate).eventManager!;
    }
    
    func fetchEventsFromDate(startDate: NSDate = NSDate.date(),
                             untilDate endDate: NSDate,
                             completion: ETFetchEventsCompletionHandler) -> NSOperation {
        let predicate = self.store.predicateForCompletedRemindersWithCompletionDateStarting(
            startDate, ending: endDate, calendars: self.calendars)
        let fetchOperation = NSBlockOperation({ () -> Void in
            self.mutableEvents = self.store.eventsMatchingPredicate(predicate) as? [EKEvent]
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
            self.addEvent(event)
            var userInfo: Dictionary<String, AnyObject> = [:]
            userInfo[ETEntityOperationNotificationTypeKey] = EKEntityTypeEvent
            userInfo[ETEntityOperationNotificationDataKey] = event
            NSNotificationCenter.defaultCenter()
                .postNotificationName(ETEntitySaveOperationNotification, object: self, userInfo: userInfo)
        }
        return didSave
    }
    
    func validateEvent(event: EKEvent, error: NSErrorPointer) -> Bool {
        let failureReasonNone = ""
        var userInfo: Dictionary<String, String> = [
            NSLocalizedDescriptionKey: NSLocalizedString("Event is invalid", comment:""),
            NSLocalizedFailureReasonErrorKey: failureReasonNone,
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please make sure event is filled in.", comment:"")
        ]
        if !event.calendar { // TODO: Anti-pattern.
            event.calendar = self.store.defaultCalendarForNewEvents
        }
        if !event.endDate ||
            event.endDate.compare(event.startDate) != NSComparisonResult.OrderedDescending
        {
            event.endDate = NSDate.dateFromAddingDays(1, toDate: event.startDate)
        }
        var failureReason :String = userInfo[NSLocalizedFailureReasonErrorKey]!
        if event.title.isEmpty {
            failureReason += NSLocalizedString(" Event title is required.", comment:"")
        }
        if !event.startDate {
            failureReason += NSLocalizedString(" Event start date is required.", comment:"")
        }
        if !event.endDate {
            failureReason += NSLocalizedString(" Event end date is required.", comment:"")
        }
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason
        let isValid = failureReason == failureReasonNone
        if !isValid && error {
            error.memory = NSError.errorWithDomain(ETErrorDomain, code: ETErrorCodeInvalidObject, userInfo: userInfo)
        }
        return true
    }
    
    private func addEvent(event: EKEvent) -> Bool {
        var didAdd = false
        if var events = self.mutableEvents {
            let bridgedEvents = events.bridgeToObjectiveC()
            if bridgedEvents.containsObject(event) {
                events += event
                bridgedEvents.sortedArrayUsingSelector(Selector("compareStartDateWithEvent:"))
                self.invalidateEvents()
                didAdd = true
            }
        }
        return didAdd
    }
    
}

extension NSDate {
    
    class func dateFromAddingDays(numberOfDays: Int, toDate date: NSDate!) -> NSDate! {
        let calendar = NSCalendar.currentCalendar()
        var dayComponents = calendar.components(
            .DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit | .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit,
            fromDate: date)
        dayComponents.hour = 0
        dayComponents.minute = 0
        dayComponents.second = 0
        let newDate = calendar.dateFromComponents(dayComponents)
        return newDate
    }
    
}