//
//  EventManager.swift
//  Eventual
//
//  Created by Peng Wang on 6/2/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import EventKit

typealias FetchEventsCompletionHandler = () -> Void
typealias DateIndexedEventCollection = [String: NSArray]

enum EventManagerError: ErrorType {
    case CalendarsNotFound
    case EventAlreadyExists(Int)
    case EventNotFound
}

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

    private(set) var monthsEvents: MonthsEvents?
    func updateEventsByMonthsAndDays() {
        self.monthsEvents = MonthsEvents(events: self.events)
    }

    static var defaultManager: EventManager {
        let eventManager = AppDelegate.sharedDelegate.eventManager
        eventManager.completeSetupIfNeeded()
        return eventManager
    }

    // MARK: - Initializers

    override init() {
        self.store = EKEventStore()
        self.operationQueue = NSOperationQueue()
        super.init()
    }

    func completeSetupIfNeeded() {
        guard self.calendar == nil else { return }
        self.store.requestAccessToEntityType(.Event) { granted, accessError in
            var userInfo: [String: AnyObject] = [:]
            userInfo[TypeKey] = EKEntityType.Event as? AnyObject
            if granted {
                userInfo[ResultKey] = EntityAccessGranted
                self.calendars = self.store.calendarsForEntityType(.Event)
                self.calendar = self.store.defaultCalendarForNewEvents
            } else if !granted {
                userInfo[ResultKey] = EntityAccessDenied
            } else if let accessError = accessError {
                userInfo[ResultKey] = EntityAccessError
                userInfo[ErrorKey] = accessError
            }
            NSNotificationCenter.defaultCenter()
                .postNotificationName(EntityAccessNotification, object: self, userInfo: userInfo)
        }
    }

}

// MARK: - CRUD

extension EventManager {

    func fetchEventsFromDate(startDate: NSDate = NSDate(),
                             untilDate endDate: NSDate,
                             completion: FetchEventsCompletionHandler) throws -> NSOperation
    {
        guard let calendars = self.calendars else { throw EventManagerError.CalendarsNotFound }

        let predicate: NSPredicate = {
            let normalizedStartDate = startDate.dayDate!, normalizedEndDate = endDate.dayDate!
            return self.store.predicateForEventsWithStartDate(
                normalizedStartDate, endDate: normalizedEndDate, calendars: calendars
            )
        }()

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

    func prepareEvent(event: EKEvent) {
        // Fill some missing blanks.
        event.calendar = event.calendar ?? self.store.defaultCalendarForNewEvents
        if event.startDate.hasCustomTime {
            event.allDay = false
            event.endDate = event.startDate.hourDateFromAddingHours(1)
        } else {
            event.allDay = true
            // EventKit auto-adjusts endDate per allDay.
            event.endDate = event.startDate
        }
    }

    func resetEvent(event: EKEvent) {
        // Given an existing event.
        guard let pristine = self.store.eventWithIdentifier(event.eventIdentifier) else { return }
        // Restore pristine values for anything our app is expected to modify.
        for key in ["allDay", "endDate", "startDate", "title"] {
            event.setValue(pristine.valueForKey(key), forKey: key)
        }
    }

    func saveEvent(event: EKEvent) throws {
        do {
            self.prepareEvent(event)
            try self.validateEvent(event)
            try self.store.saveEvent(event, span: .ThisEvent, commit: true)
            let events = self.events as [NSObject]
            do {
                try self.events = self.addEvent(event as NSObject, toEvents: events) as! [EKEvent]
            } catch EventManagerError.EventAlreadyExists(let index) {
                try self.events = self.replaceEvent(event as NSObject, inEvents: events, atIndex: index) as! [EKEvent]
            }
            self.postSaveNotificationForEvent(event)
        }
    }

    // MARK: Helpers

    func addEvent(event: NSObject, var toEvents events: [NSObject]) throws -> [AnyObject] {
        if let index = self.indexOfEvent(event, inEvents: events) {
            throw EventManagerError.EventAlreadyExists(index)
        }
        // TODO: Edited event gets copied around and fetched events becomes stale.
        events.append(event)
        return self.sortedEvents(events as NSArray)
    }

    func replaceEvent(event: NSObject, var inEvents events: [NSObject], atIndex index: Int? = nil) throws -> [AnyObject] {
        guard let index = index ?? self.indexOfEvent(event, inEvents: events) else {
            throw EventManagerError.EventNotFound
        }
        events.removeAtIndex(index)
        events.append(event)
        return self.sortedEvents(events as NSArray)
    }

    private func indexOfEvent(event: NSObject, inEvents events: [NSObject]) -> Int? {
        return events.indexOf { (e) -> Bool in
            return e.valueForKey("eventIdentifier")?.isEqual(event.valueForKey("eventIdentifier")) ?? false
        }
    }

    private func postSaveNotificationForEvent(event: EKEvent) {
        var userInfo: [String: AnyObject] = [:]
        userInfo[TypeKey] = EKEntityType.Event.rawValue
        userInfo[DataKey] = event
        NSNotificationCenter.defaultCenter()
            .postNotificationName(EntitySaveOperationNotification, object: self, userInfo: userInfo)
    }

    private func sortedEvents(events: NSArray) -> [AnyObject] {
        return events.sortedArrayUsingSelector(Selector("compareStartDateWithEvent:"))
    }

}

// MARK: - Validation

extension EventManager {

    func validateEvent(event: EKEvent) throws {
        var userInfo: [String: String] = [
            NSLocalizedDescriptionKey: t("Event is invalid"),
            NSLocalizedRecoverySuggestionErrorKey: t("Please make sure event is filled in.")
        ]
        var failureReason: [String] = []
        if event.title.isEmpty {
            failureReason.append(t("Event title is required."))
        }
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason.joinWithSeparator(" ")
        let isValid = failureReason.isEmpty
        if !isValid {
            throw NSError(domain: ErrorDomain, code: ErrorCode.InvalidObject.rawValue, userInfo: userInfo)
        }
    }

}

// MARK: - Data Classes

typealias DayEvents = NSArray

class MonthEvents {

    let days: NSMutableArray = []
    let events: NSMutableArray = []

    func dayForEvent(event: EKEvent) -> NSDate? {
        guard let startDate = event.valueForKey("startDate") as? NSDate else { return nil }
        let day = startDate.dayDate!
        if self.days.indexOfObject(day) == NSNotFound {
            self.days.addObject(day)
        }
        return day
    }

    func dayEventsForEvent(event: EKEvent, day: NSDate) -> NSMutableArray {
        let dayEvents: NSMutableArray
        let index = self.days.indexOfObject(day)
        if index != NSNotFound && self.events.count > index {
            dayEvents = self.events[index] as! NSMutableArray
        } else {
            dayEvents = []
            self.events.addObject(dayEvents)
        }
        return dayEvents
    }

    func dayEventsForDate(date: NSDate) -> DayEvents? {
        guard let day = date.dayDate else { return nil }
        let index = self.days.indexOfObject(day)
        guard index != NSNotFound, let dayEvents = self.events[index] as? DayEvents else { return nil }
        return dayEvents
    }

}

class MonthsEvents {

    var months: NSMutableArray = []
    var events: NSMutableArray = []

    init(events: [EKEvent]) {
        for event in events {
            guard let month = self.monthForEvent(event) else { continue }
            let monthEvents = self.monthEventsForEvent(event, month: month)
            guard let day = monthEvents.dayForEvent(event) else { continue }
            let dayEvents = monthEvents.dayEventsForEvent(event, day: day)
            dayEvents.addObject(event)
        }
    }

    func monthForEvent(event: EKEvent) -> NSDate? {
        guard let startDate = event.valueForKey("startDate") as? NSDate else { return nil }
        let month = startDate.monthDate!
        if self.months.indexOfObject(month) == NSNotFound {
            self.months.addObject(month)
        }
        return month
    }

    func monthEventsForEvent(event: EKEvent, month: NSDate) -> MonthEvents {
        let monthEvents: MonthEvents
        let index = self.months.indexOfObject(month)
        if index != NSNotFound && self.events.count > index {
            monthEvents = self.events[index] as! MonthEvents
        } else {
            monthEvents = MonthEvents()
            self.events.addObject(monthEvents)
        }
        return monthEvents
    }

    func monthEventsForDate(date: NSDate) -> MonthEvents? {
        guard let month = date.monthDate else { return nil }
        let index = self.months.indexOfObject(month)
        guard index != NSNotFound, let monthEvents = self.events[index] as? MonthEvents else { return nil }
        return monthEvents
    }

    func dayEventsAtIndexPath(indexPath: NSIndexPath) -> DayEvents? {
        return self.monthEventsAtIndexPath(indexPath)?.events[indexPath.item] as? DayEvents
    }

    // NSIndexPath

    func monthEventsAtIndexPath(indexPath: NSIndexPath) -> MonthEvents? {
        return self.events[indexPath.section] as? MonthEvents
    }

    func dayEventsForDate(date: NSDate) -> DayEvents {
        return self.monthEventsForDate(date)?.dayEventsForDate(date) ?? []
    }

    func dayAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        return self.monthEventsAtIndexPath(indexPath)?.days[indexPath.item] as? NSDate
    }

    func daysForMonthAtIndex(index: Int) -> NSArray? {
        guard self.months.count > index else { return nil }
        return (self.events[index] as? MonthEvents)?.days
    }

}
