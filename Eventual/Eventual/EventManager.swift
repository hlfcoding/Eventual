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
typealias ETEventByMonthAndDayCollection = [String: NSArray]

@objc(ETEventManager) class EventManager: NSObject {
    
    var store: EKEventStore!
    
    private var operationQueue: NSOperationQueue!
    
    private var calendars: [EKCalendar]?
    private var calendar: EKCalendar?
    
    var events: [EKEvent]? { return self.mutableEvents }
    private var mutableEvents: [EKEvent]? {
        didSet {
            if self.mutableEvents == nil && oldValue == nil { return }
            let didChange = self.mutableEvents == nil || oldValue == nil || self.mutableEvents! != oldValue! // FIXME: Sigh.
            if didChange {
                self.updateEventsByMonthsAndDays()
            }
        }
    }

    // MARK: - Parsing

    var eventsByMonthsAndDays: ETEventByMonthAndDayCollection?
    func updateEventsByMonthsAndDays() {
        if let events = self.events {
            var months: [String: NSMutableArray] = [:]
            var monthsDates: NSMutableArray = []
            var monthsDays: NSMutableArray = []
            let calendar = NSCalendar.currentCalendar()
            for event in events {
                let monthComponents = calendar.components(.CalendarUnitMonth | .YearCalendarUnit, fromDate: event.startDate)
                let dayComponents = calendar.components(.DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit, fromDate: event.startDate)
                let monthDate = calendar.dateFromComponents(monthComponents)!
                let dayDate = calendar.dateFromComponents(dayComponents)!
                
                let monthIndex = monthsDates.indexOfObject(monthDate)
                let needsNewMonth = monthIndex == NSNotFound
                var days: [String: NSMutableArray] = needsNewMonth ? [:] : monthsDays[monthIndex] as [String: NSMutableArray]
                var daysDates: NSMutableArray = needsNewMonth ? [] : days[ETEntityCollectionDatesKey]!
                var daysEvents: NSMutableArray = needsNewMonth ? [] : days[ETEntityCollectionEventsKey]!
                if needsNewMonth {
                    monthsDates.addObject(monthDate)
                    days[ETEntityCollectionDatesKey] = daysDates
                    days[ETEntityCollectionEventsKey] = daysEvents
                    monthsDays.addObject(days)
                }
                
                let dayIndex = daysDates.indexOfObject(dayDate)
                let needsNewDay = dayIndex == NSNotFound
                var dayEvents: NSMutableArray = needsNewDay ? [] : daysEvents[dayIndex] as NSMutableArray
                if needsNewDay {
                    daysDates.addObject(dayDate)
                    daysEvents.addObject(dayEvents)
                }
                dayEvents.addObject(event)
            }
            months[ETEntityCollectionDatesKey] = monthsDates
            months[ETEntityCollectionDaysKey] = monthsDays
            self.eventsByMonthsAndDays = months
        }
    }
    
    // MARK: - Initializers

    override init() {
        self.store = EKEventStore()
        self.operationQueue = NSOperationQueue()
        super.init()
    }

    func completeSetup() {
        self.store.requestAccessToEntityType(EKEntityTypeEvent) { granted, accessError in
            var userInfo: [String: AnyObject] = [:]
            userInfo[ETEntityAccessRequestNotificationTypeKey] = EKEntityTypeEvent
            if granted {
                userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationGranted
                self.calendars = self.store.calendarsForEntityType(EKEntityTypeEvent) as? [EKCalendar]
                self.calendar = self.store.defaultCalendarForNewEvents
            } else if !granted {
                userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationDenied
            } else if accessError != nil {
                userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationError
                userInfo[ETEntityAccessRequestNotificationErrorKey] = accessError
            }
            NSNotificationCenter.defaultCenter()
                .postNotificationName(ETEntityAccessRequestNotification, object: self, userInfo: userInfo)
        }
    }

    class func defaultManager() -> EventManager! {
        return (UIApplication.sharedApplication().delegate as AppDelegate).eventManager;
    }

}

// MARK: - CRUD

extension EventManager {

    func fetchEventsFromDate(startDate: NSDate = NSDate.date(),
                             untilDate endDate: NSDate,
                             completion: ETFetchEventsCompletionHandler) -> NSOperation
    {
        let predicate = self.store.predicateForEventsWithStartDate(startDate, endDate: endDate, calendars: self.calendars)
        let fetchOperation = NSBlockOperation {
            self.mutableEvents = self.store.eventsMatchingPredicate(predicate) as? [EKEvent]
        }
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
            var userInfo: [String: AnyObject] = [:]
            userInfo[ETEntityOperationNotificationTypeKey] = EKEntityTypeEvent
            userInfo[ETEntityOperationNotificationDataKey] = event
            NSNotificationCenter.defaultCenter()
                .postNotificationName(ETEntitySaveOperationNotification, object: self, userInfo: userInfo)
        }
        return didSave
    }

}

// MARK: - Validation

extension EventManager {

    func validateEvent(event: EKEvent, error: NSErrorPointer) -> Bool {
        let failureReasonNone = ""
        var userInfo: [String: String] = [
            NSLocalizedDescriptionKey: NSLocalizedString("Event is invalid", comment:""),
            NSLocalizedFailureReasonErrorKey: failureReasonNone,
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please make sure event is filled in.", comment:"")
        ]
        if event.calendar == nil {
            event.calendar = self.store.defaultCalendarForNewEvents
        }
        if (event.endDate == nil ||
            event.endDate.compare(event.startDate) != NSComparisonResult.OrderedDescending)
        {
            event.endDate = NSDate.dateFromAddingDays(1, toDate: event.startDate)
        }
        var failureReason: String = userInfo[NSLocalizedFailureReasonErrorKey]!
        if event.title != nil && event.title.isEmpty {
            failureReason += NSLocalizedString(" Event title is required.", comment:"")
        }
        if event.startDate == nil {
            failureReason += NSLocalizedString(" Event start date is required.", comment:"")
        }
        if event.endDate == nil {
            failureReason += NSLocalizedString(" Event end date is required.", comment:"")
        }
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason
        let isValid = failureReason == failureReasonNone
        if !isValid && error != nil {
            error.memory = NSError.errorWithDomain(ETErrorDomain, code: ETErrorCode.InvalidObject.toRaw(), userInfo: userInfo)
        }
        return true
    }
    
}

// MARK: - Helpers

extension EventManager {

    private func addEvent(event: EKEvent) -> Bool {
        var didAdd = false
        if var events = self.mutableEvents {
            let bridgedEvents = events as NSArray
            if bridgedEvents.containsObject(event) {
                events.append(event)
                bridgedEvents.sortedArrayUsingSelector(Selector("compareStartDateWithEvent:"))
                self.updateEventsByMonthsAndDays()
                didAdd = true
            }
        }
        return didAdd
    }
    
}

// MARK: - Internal Additions

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
