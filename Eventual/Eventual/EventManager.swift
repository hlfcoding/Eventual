//
//  EventManager.swift
//  Eventual
//
//  Created by Nest Master on 6/2/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import EventKit

let EntityAccessRequestNotification = "EntityAccess"

let EntityAccessRequestNotificationDenied = "EntityAccessDenied"
let EntityAccessRequestNotificationError = "EntityAccessError"
let EntityAccessRequestNotificationGranted = "EntityAccessGranted"

let EntityAccessRequestNotificationErrorKey = "EntityAccessErrorKey"
let EntityAccessRequestNotificationResultKey = "EntityAccessResultKey"
let EntityAccessRequestNotificationTypeKey = "EntityAccessTypeKey"

let EntitySaveOperationNotification = "EntitySaveOperation"
let EntityOperationNotificationTypeKey = "EntityOperationTypeKey"
let EntityOperationNotificationDataKey = "EntityOperationDataKey"

let EntityCollectionDatesKey = "dates"
let EntityCollectionDaysKey = "days"
let EntityCollectionEventsKey = "events"

typealias FetchEventsCompletionHandler = () -> Void
typealias EventByMonthAndDayCollection = [String: NSArray]

class EventManager: NSObject {
    
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

    var eventsByMonthsAndDays: EventByMonthAndDayCollection?
    func updateEventsByMonthsAndDays() {
        var months: [String: NSMutableArray] = [:]
        let monthsDates: NSMutableArray = []
        let monthsDays: NSMutableArray = []
        for event in self.events {
            // Months date array and days array.
            let monthDate = event.startDate.monthDate!
            let monthIndex = monthsDates.indexOfObject(monthDate)
            let needsNewMonth = monthIndex == NSNotFound
            var days: [String: NSMutableArray] = needsNewMonth ? [:] : monthsDays[monthIndex] as! [String: NSMutableArray]
            let daysDates: NSMutableArray = needsNewMonth ? [] : days[EntityCollectionDatesKey]!
            let daysEvents: NSMutableArray = needsNewMonth ? [] : days[EntityCollectionEventsKey]!
            if needsNewMonth {
                monthsDates.addObject(monthDate)
                days[EntityCollectionDatesKey] = daysDates
                days[EntityCollectionEventsKey] = daysEvents
                monthsDays.addObject(days)
            }
            // Days dates array and events array.
            let dayDate = event.startDate.dayDate!
            let dayIndex = daysDates.indexOfObject(dayDate)
            let needsNewDay = dayIndex == NSNotFound
            let dayEvents: NSMutableArray = needsNewDay ? [] : daysEvents[dayIndex] as! NSMutableArray
            if needsNewDay {
                daysDates.addObject(dayDate)
                daysEvents.addObject(dayEvents)
            }
            dayEvents.addObject(event)
        }
        months[EntityCollectionDatesKey] = monthsDates
        months[EntityCollectionDaysKey] = monthsDays
        // TODO: Integrate with Settings bundle entry.
        // println(months)
        self.eventsByMonthsAndDays = months
    }
    
    func eventsForDayDate(date: NSDate) -> NSArray {
        // Find and select month, then day, then events from parsed events
        guard let months = self.eventsByMonthsAndDays,
                  monthDate = date.monthDate,
                  monthIndex = months[EntityCollectionDatesKey]?.indexOfObject(monthDate),
                  days = months[EntityCollectionDaysKey]?[monthIndex] as? [String: NSArray],
                  dayDate = date.dayDate,
                  dayIndex = days[EntityCollectionDatesKey]?.indexOfObject(dayDate)
              where dayIndex != NSNotFound,
              let dayEvents = days[EntityCollectionEventsKey]?[dayIndex] as? NSArray
              else { return [] }
        return dayEvents
    }
    
    // MARK: - Initializers

    override init() {
        self.store = EKEventStore()
        self.operationQueue = NSOperationQueue()
        super.init()
    }

    func completeSetup() {
        if self.calendar != nil { return }
        self.store.requestAccessToEntityType(.Event) { granted, accessError in
            var userInfo: [String: AnyObject] = [:]
            userInfo[EntityAccessRequestNotificationTypeKey] = EKEntityType.Event as? AnyObject
            if granted {
                userInfo[EntityAccessRequestNotificationResultKey] = EntityAccessRequestNotificationGranted
                self.calendars = self.store.calendarsForEntityType(.Event)
                self.calendar = self.store.defaultCalendarForNewEvents
            } else if !granted {
                userInfo[EntityAccessRequestNotificationResultKey] = EntityAccessRequestNotificationDenied
            } else if accessError != nil {
                userInfo[EntityAccessRequestNotificationResultKey] = EntityAccessRequestNotificationError
                userInfo[EntityAccessRequestNotificationErrorKey] = accessError
            }
            NSNotificationCenter.defaultCenter()
                .postNotificationName(EntityAccessRequestNotification, object: self, userInfo: userInfo)
        }
    }

    class func defaultManager() -> EventManager? {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).eventManager
    }

}

// MARK: - CRUD

extension EventManager {

    func fetchEventsFromDate(startDate: NSDate = NSDate(),
                             untilDate endDate: NSDate,
                             completion: FetchEventsCompletionHandler) -> NSOperation
    {
        let normalizedStartDate = startDate.dayDate!
        let normalizedEndDate = endDate.dayDate!
        let predicate = self.store.predicateForEventsWithStartDate(normalizedStartDate, endDate: normalizedEndDate, calendars: self.calendars)
        let fetchOperation = NSBlockOperation {
            let events: NSArray = self.store.eventsMatchingPredicate(predicate)
            self.events = events.sortedArrayUsingSelector(Selector("compareStartDateWithEvent:")) as! [EKEvent]
        }
        fetchOperation.queuePriority = NSOperationQueuePriority.VeryHigh
        let completionOperation = NSBlockOperation(block: completion)
        completionOperation.addDependency(fetchOperation)
        self.operationQueue.addOperation(fetchOperation)
        NSOperationQueue.mainQueue().addOperation(completionOperation)
        return fetchOperation
    }
    
    func saveEvent(event: EKEvent) throws {
        do {
            try self.store.saveEvent(event, span: .ThisEvent, commit: true)
            try self.validateEvent(event)
            if !self.addEvent(event) && !self.replaceEvent(event) {
                fatalError("Unable to update fetched events with event \(event.eventIdentifier)")
            }
            var userInfo: [String: AnyObject] = [:]
            userInfo[EntityOperationNotificationTypeKey] = EKEntityType.Event as? AnyObject
            userInfo[EntityOperationNotificationDataKey] = event
            NSNotificationCenter.defaultCenter()
                .postNotificationName(EntitySaveOperationNotification, object: self, userInfo: userInfo)
        }
    }

}

// MARK: - Validation

extension EventManager {

    func validateEvent(event: EKEvent) throws {
        let failureReasonNone = ""
        var userInfo: [String: String] = [
            NSLocalizedDescriptionKey: t("Event is invalid"),
            NSLocalizedFailureReasonErrorKey: failureReasonNone,
            NSLocalizedRecoverySuggestionErrorKey: t("Please make sure event is filled in.")
        ]
        event.calendar = event.calendar ?? self.store.defaultCalendarForNewEvents
        var failureReason: String = userInfo[NSLocalizedFailureReasonErrorKey]!
        if event.title.isEmpty {
            failureReason += t(" Event title is required.")
        }
        var newEndDate = event.startDate.dayDateFromAddingDays(1)
        if event.endDate.laterDate(newEndDate) == event.endDate {
            newEndDate = event.endDate
        }
        event.endDate = newEndDate // Might be redundant.
        event.allDay = !event.startDate.hasCustomTime
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason
        let isValid = failureReason == failureReasonNone
        if !isValid {
            throw NSError(domain: ErrorDomain, code: ErrorCode.InvalidObject.rawValue, userInfo: userInfo)
        }
    }
    
}

// MARK: - Helpers

extension EventManager {

    private func addEvent(event: EKEvent) -> Bool {
        var shouldAdd = true
        for existingEvent in self.events {
            // TODO: Edited event gets copied around and fetched events becomes stale.
            if event.eventIdentifier == existingEvent.eventIdentifier {
                shouldAdd = false
                break
            }
        }
        if shouldAdd {
            self.events.append(event)
            self.events = (self.events as NSArray).sortedArrayUsingSelector(Selector("compareStartDateWithEvent:")) as! [EKEvent]
        }
        return shouldAdd
    }
    
    private func replaceEvent(event: EKEvent) -> Bool {
        for (index, existingEvent) in self.events.enumerate() {
            if event.eventIdentifier == existingEvent.eventIdentifier {
                self.events.removeAtIndex(index)
                self.events.append(event)
                self.events = (self.events as NSArray).sortedArrayUsingSelector(Selector("compareStartDateWithEvent:")) as! [EKEvent]
                return true
            }
        }
        return false
    }
    
}

// MARK: - Internal Additions

extension NSDate {
    
    func dayDateFromAddingDays(numberOfDays: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = numberOfDays
        return calendar.dateByAddingComponents(components, toDate: self.dayDate!, options: [])!
    }

    func hourDateFromAddingHours(numberOfHours: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.hour = numberOfHours
        return calendar.dateByAddingComponents(components, toDate: self.hourDate!, options: [])!
    }

    var hasCustomTime: Bool {
        return NSCalendar.currentCalendar().component(.Hour, fromDate: self) > 0
    }

    func dateWithTime(timeDate: NSDate) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(DayUnitFlags, fromDate: self)
        var hour: Int = 0; var minute: Int = 0; var second: Int = 0
        calendar.getHour(&hour, minute: &minute, second: &second, nanosecond: nil, fromDate: timeDate)
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.dateFromComponents(components)!
    }

    func flooredDateWithComponents(unitFlags: NSCalendarUnit) -> NSDate? {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(calendar.components(unitFlags, fromDate: self))
    }

    var dayDate: NSDate? { return self.flooredDateWithComponents(DayUnitFlags) }
    var hourDate: NSDate? { return self.flooredDateWithComponents(HourUnitFlags) }
    var monthDate: NSDate? { return self.flooredDateWithComponents(MonthUnitFlags) }

}
