//
//  EventManager.swift
//  Eventual
//
//  Created by Peng Wang on 6/2/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import EventKit

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

    /**
     Stores fetched events in memory for faster access.
     */
    private var entities: [EKEvent] = [] {
        didSet {
            if self.entities != oldValue {
                self.updateEventsByMonthsAndDays()
            }
        }
    }

    /**
     Structured events collection to use as UI data source.
     */
    private(set) var monthsEvents: MonthsEvents?
    func updateEventsByMonthsAndDays() {
        let events = self.entities.map { Event(entity: $0) }
        self.monthsEvents = MonthsEvents(events: events)
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
                             completion: () -> Void) throws -> NSOperation
    {
        guard let calendars = self.calendars else { throw EventManagerError.CalendarsNotFound }

        let predicate: NSPredicate = {
            let normalizedStartDate = startDate.dayDate!, normalizedEndDate = endDate.dayDate!
            return self.store.predicateForEventsWithStartDate(
                normalizedStartDate, endDate: normalizedEndDate, calendars: calendars
            )
        }()

        let fetchOperation = NSBlockOperation {
            let entities: NSArray = self.store.eventsMatchingPredicate(predicate)
            self.entities = entities.sortedArrayUsingSelector(Selector("compareStartDateWithEvent:")) as! [EKEvent]
        }
        fetchOperation.queuePriority = NSOperationQueuePriority.VeryHigh
        let completionOperation = NSBlockOperation(block: completion)
        completionOperation.addDependency(fetchOperation)
        self.operationQueue.addOperation(fetchOperation)
        NSOperationQueue.mainQueue().addOperation(completionOperation)
        return fetchOperation
    }

    func prepareEvent(event: Event) {
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

    func saveEvent(event: Event) throws {
        do {
            self.prepareEvent(event)
            try self.validateEvent(event)
            event.commitChanges()

            try self.store.saveEvent(event.entity, span: .ThisEvent, commit: true)

            let entities = self.entities as [NSObject]
            do {
                try self.entities = self.addEvent(event as NSObject, toEvents: entities) as! [EKEvent]

            } catch EventManagerError.EventAlreadyExists(let index) {
                try self.entities = self.replaceEvent(event as NSObject, inEvents: entities, atIndex: index) as! [EKEvent]
            }
            event.resetChanges()
            self.postSaveNotificationForEvent(event)
        }
    }

    // MARK: Helpers

    func addEvent(entity: NSObject, var toEvents entities: [NSObject]) throws -> [AnyObject] {
        if let index = self.indexOfEvent(entity, inEvents: entities) {
            throw EventManagerError.EventAlreadyExists(index)
        }
        // TODO: Edited event gets copied around and fetched events becomes stale.
        entities.append(entity)
        return self.sortedEvents(entities)
    }

    func replaceEvent(entity: NSObject, var inEvents entities: [NSObject], atIndex index: Int? = nil) throws -> [AnyObject] {
        guard let index = index ?? self.indexOfEvent(entity, inEvents: entities) else {
            throw EventManagerError.EventNotFound
        }
        entities.removeAtIndex(index)
        entities.append(entity)
        return self.sortedEvents(entities)
    }

    private func indexOfEvent(entity: NSObject, inEvents entities: [NSObject]) -> Int? {
        return entities.indexOf { (e) -> Bool in
            return e.valueForKey("eventIdentifier")?.isEqual(entity.valueForKey("eventIdentifier")) ?? false
        }
    }

    private func postSaveNotificationForEvent(event: Event) {
        var userInfo: [String: AnyObject] = [:]
        userInfo[TypeKey] = EKEntityType.Event.rawValue
        userInfo[DataKey] = event
        NSNotificationCenter.defaultCenter()
            .postNotificationName(EntitySaveOperationNotification, object: self, userInfo: userInfo)
    }

    private func sortedEvents(entities: [NSObject]) -> [AnyObject] {
        return (entities as NSArray).sortedArrayUsingSelector(Selector("compareStartDateWithEvent:"))
    }

}

// MARK: - Validation

extension EventManager {

    func validateEvent(event: Event) throws {
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