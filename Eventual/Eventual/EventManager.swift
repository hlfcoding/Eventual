//
//  EventManager.swift
//  Eventual
//
//  Created by Nest Master on 6/2/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import EventKit

typealias FetchEventsCompletionHandler = () -> Void
typealias DateIndexedEventCollection = [String: NSArray]

enum EventManagerError: ErrorType {
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

    // MARK: - Parsing

    var eventsByMonthsAndDays: DateIndexedEventCollection?
    func updateEventsByMonthsAndDays() {
        self.eventsByMonthsAndDays = self.arrangeToEventsByMonthsAndDays(self.events)
    }
    func arrangeToEventsByMonthsAndDays(events: [NSObject]) -> DateIndexedEventCollection {
        var months: [String: NSMutableArray] = [:]
        let monthsDates: NSMutableArray = []
        let monthsDays: NSMutableArray = []
        for event in events {
            // Months date array and days array.
            guard let startDate = event.valueForKey("startDate") as? NSDate else { continue }
            let monthDate = startDate.monthDate!
            let monthIndex = monthsDates.indexOfObject(monthDate)
            let needsNewMonth = monthIndex == NSNotFound
            var days: [String: NSMutableArray] = needsNewMonth ? [:] : monthsDays[monthIndex] as! [String: NSMutableArray]
            let daysDates: NSMutableArray = needsNewMonth ? [] : days[DatesKey]!
            let daysEvents: NSMutableArray = needsNewMonth ? [] : days[EventsKey]!
            if needsNewMonth {
                monthsDates.addObject(monthDate)
                days[DatesKey] = daysDates
                days[EventsKey] = daysEvents
                monthsDays.addObject(days)
            }
            // Days dates array and events array.
            let dayDate = startDate.dayDate!
            let dayIndex = daysDates.indexOfObject(dayDate)
            let needsNewDay = dayIndex == NSNotFound
            let dayEvents: NSMutableArray = needsNewDay ? [] : daysEvents[dayIndex] as! NSMutableArray
            if needsNewDay {
                daysDates.addObject(dayDate)
                daysEvents.addObject(dayEvents)
            }
            dayEvents.addObject(event)
        }
        months[DatesKey] = monthsDates
        months[DaysKey] = monthsDays
        // TODO: Integrate with Settings bundle entry.
        // print(months)
        return months
    }
    
    func eventsForDayDate(date: NSDate, months: DateIndexedEventCollection? = nil) -> NSArray {
        // Find and select month, then day, then events from parsed events
        guard let months = months ?? self.eventsByMonthsAndDays,
                  monthDate = date.monthDate, dayDate = date.dayDate,
                  monthIndex = months[DatesKey]?.indexOfObject(monthDate),
                  days = months[DaysKey]?[monthIndex] as? DateIndexedEventCollection,
              let dayIndex = days[DatesKey]?.indexOfObject(dayDate) where dayIndex != NSNotFound,
              let dayEvents = days[EventsKey]?[dayIndex] as? NSArray
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

    class func defaultManager() -> EventManager? {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).eventManager
    }

}

// MARK: - CRUD

extension EventManager {

    func fetchEventsFromDate(startDate: NSDate = NSDate(),
                             untilDate endDate: NSDate,
                             completion: FetchEventsCompletionHandler) -> NSOperation?
    {
        let normalizedStartDate = startDate.dayDate!
        let normalizedEndDate = endDate.dayDate!
        let predicate = self.store.predicateForEventsWithStartDate(normalizedStartDate, endDate: normalizedEndDate, calendars: self.calendars)
        guard NSUserDefaults.standardUserDefaults().objectForKey("SynchronousData") == nil else {
            let events: NSArray = self.store.eventsMatchingPredicate(predicate)
            self.events = events.sortedArrayUsingSelector(Selector("compareStartDateWithEvent:")) as! [EKEvent]
            completion()
            return nil
        }
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

    func saveEvent(event: EKEvent) throws {
        do {
            self.prepareEvent(event)
            try self.validateEvent(event)
            try self.store.saveEvent(event, span: .ThisEvent, commit: true)
            do {
                try self.events = self.addEvent(event as NSObject, toEvents: self.events as [NSObject]) as! [EKEvent]
            } catch EventManagerError.EventAlreadyExists(let index) {
                try self.events = self.replaceEvent(event as NSObject, inEvents: self.events as [NSObject], atIndex: index) as! [EKEvent]
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

// MARK: - Helpers

extension EventManager {


}

// MARK: - Internal Additions

extension NSDate {
    
    func dayDateFromAddingDays(numberOfDays: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = numberOfDays
        return calendar.dateByAddingComponents(components, toDate: self, options: [])!.dayDate!
    }

    func hourDateFromAddingHours(numberOfHours: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.hour = numberOfHours
        return calendar.dateByAddingComponents(components, toDate: self, options: [])!.hourDate!
    }

    var hasCustomTime: Bool {
        return NSCalendar.currentCalendar().component(.Hour, fromDate: self) > 0
    }

    func dateWithTime(timeDate: NSDate) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let timeComponents = calendar.components([.Hour, .Minute, .Second], fromDate: timeDate)
        return calendar.dateBySettingHour(timeComponents.hour, minute: timeComponents.minute, second: timeComponents.second, ofDate: self, options: [.WrapComponents])!
    }

    func flooredDateWithComponents(unitFlags: NSCalendarUnit) -> NSDate? {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(calendar.components(unitFlags, fromDate: self))
    }

    var dayDate: NSDate? { return self.flooredDateWithComponents(DayUnitFlags) }
    var hourDate: NSDate? { return self.flooredDateWithComponents(HourUnitFlags) }
    var monthDate: NSDate? { return self.flooredDateWithComponents(MonthUnitFlags) }

}
