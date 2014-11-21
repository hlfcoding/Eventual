//
//  ETEventManager.swift
//  Eventual
//
//  Created by Nest Master on 6/2/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
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
    
    var events: [EKEvent] = [] {
        didSet {
            if self.events != oldValue {
                self.updateEventsByMonthsAndDays()
            }
        }
    }

    // MARK: - Parsing

    var eventsByMonthsAndDays: ETEventByMonthAndDayCollection?
    func updateEventsByMonthsAndDays() {
        var months: [String: NSMutableArray] = [:]
        var monthsDates: NSMutableArray = []
        var monthsDays: NSMutableArray = []
        for event in events {
            // Months date array and days array.
            let monthDate = event.startDate.monthDate!
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
            // Days dates array and events array.
            let dayDate = event.startDate.dayDate!
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
    
    func eventsForDayDate(date: NSDate) -> NSArray {
        // Select from parsed events.
        let months = self.eventsByMonthsAndDays
        if months == nil { return [] }
        // Find and select month.
        let monthDate = date.monthDate!
        let monthIndex = months![ETEntityCollectionDatesKey]!.indexOfObject(monthDate)
        let days = months![ETEntityCollectionDaysKey]![monthIndex] as [String: NSArray]
        // Find and select day.
        let dayDate = date.dayDate!
        let dayIndex = days[ETEntityCollectionDatesKey]!.indexOfObject(dayDate)
        return days[ETEntityCollectionEventsKey]![dayIndex] as NSArray
    }
    
    // MARK: - Initializers

    override init() {
        self.store = EKEventStore()
        self.operationQueue = NSOperationQueue()
        super.init()
    }

    func completeSetup() {
        if self.calendar != nil { return }
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
        return (UIApplication.sharedApplication().delegate as AppDelegate).eventManager
    }

}

// MARK: - CRUD

extension EventManager {

    func fetchEventsFromDate(startDate: NSDate = NSDate.date(),
                             untilDate endDate: NSDate,
                             completion: ETFetchEventsCompletionHandler) -> NSOperation
    {
        var startDate = NSDate.dateAsBeginningOfDayFromAddingDays(0, toDate: startDate)
        let predicate = self.store.predicateForEventsWithStartDate(startDate, endDate: endDate, calendars: self.calendars)
        let fetchOperation = NSBlockOperation {
            self.events = (self.store.eventsMatchingPredicate(predicate) as NSArray)
                .sortedArrayUsingSelector(Selector("compareStartDateWithEvent:")) as [EKEvent]
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
            NSLocalizedDescriptionKey: t("Event is invalid"),
            NSLocalizedFailureReasonErrorKey: failureReasonNone,
            NSLocalizedRecoverySuggestionErrorKey: t("Please make sure event is filled in.")
        ]
        if event.calendar == nil {
            event.calendar = self.store.defaultCalendarForNewEvents
        }
        if event.endDate == nil ||
           event.endDate.compare(event.startDate) != NSComparisonResult.OrderedDescending
        {
            event.endDate = NSDate.dateAsBeginningOfDayFromAddingDays(1, toDate: event.startDate)
        }
        var failureReason: String = userInfo[NSLocalizedFailureReasonErrorKey]!
        if event.title != nil && event.title.isEmpty {
            failureReason += t(" Event title is required.")
        }
        if event.startDate == nil {
            failureReason += t(" Event start date is required.")
        }
        if event.endDate == nil {
            failureReason += t(" Event end date is required.")
        }
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason
        let isValid = failureReason == failureReasonNone
        if !isValid && error != nil {
            error.memory = NSError.errorWithDomain(ETErrorDomain, code: ETErrorCode.InvalidObject.toRaw(), userInfo: userInfo)
        }
        return isValid
    }
    
}

// MARK: - Helpers

extension EventManager {

    private func addEvent(event: EKEvent) -> Bool {
        var didAdd = false
        if find(events, event) == nil {
            events.append(event)
            self.events = (events as NSArray).sortedArrayUsingSelector(Selector("compareStartDateWithEvent:")) as [EKEvent]
            didAdd = true
        }
        return didAdd
    }
    
}

// MARK: - Internal Additions

extension NSDate {
    
    // TODO: Change to instance method.
    class func dateAsBeginningOfDayFromAddingDays(numberOfDays: Int, toDate date: NSDate) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        var dayComponents = calendar.components(
            .DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit | .HourCalendarUnit | .MinuteCalendarUnit | .SecondCalendarUnit,
            fromDate: date)
        dayComponents.hour = 0
        dayComponents.minute = 0
        dayComponents.second = 0
        dayComponents.day += numberOfDays
        let newDate = calendar.dateFromComponents(dayComponents)!
        return newDate
    }
    
    var dayDate: NSDate? {
        let calendar = NSCalendar.currentCalendar()
        let dayComponents = calendar.components(
            .DayCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit,
            fromDate: self
        )
        return calendar.dateFromComponents(dayComponents)
    }
    
    var monthDate: NSDate? {
        let calendar = NSCalendar.currentCalendar()
        let monthComponents = calendar.components(
            .CalendarUnitMonth | .YearCalendarUnit,
            fromDate: self
        )
        return calendar.dateFromComponents(monthComponents)
    }
    
}
