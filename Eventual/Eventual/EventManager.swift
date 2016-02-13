//
//  EventManager.swift
//  Eventual
//
//  Created by Peng Wang on 6/2/14.
//  Copyright (c) 2014-2016 Eventual App. All rights reserved.
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
     Stores wrapped, fetched events in memory for faster access.
     */
    private var mutableEvents: [Event] = []
    var events: NSArray { return self.mutableEvents as NSArray }

    /**
     Structured events collection to use as UI data source.
     */
    private(set) var monthsEvents: MonthsEvents?
    func updateEventsByMonthsAndDays() {
        self.monthsEvents = MonthsEvents(events: self.mutableEvents)
    }

    static var defaultManager: EventManager {
        let eventManager = AppDelegate.sharedDelegate.eventManager
        eventManager.completeSetupIfNeeded()
        return eventManager
    }

    // MARK: - Initializers

    override init() {
        super.init()

        self.store = EKEventStore()
        self.operationQueue = NSOperationQueue()
    }

    convenience init(events: [Event]) {
        self.init()

        self.mutableEvents = events
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
            self.mutableEvents = self.store.eventsMatchingPredicate(predicate).map { Event(entity: $0) }
            self.sortEvents()
            self.updateEventsByMonthsAndDays()
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

            do {
                try self.addEvent(event)

            } catch EventManagerError.EventAlreadyExists(let index) {
                try self.replaceEvent(event, atIndex: index)
            }
            self.updateEventsByMonthsAndDays()

            self.postSaveNotificationForEvent(event)
        }
    }

    // MARK: Helpers

    func addEvent(event: Event) throws {
        if let index = self.indexOfEvent(event) {
            throw EventManagerError.EventAlreadyExists(index)
        }
        self.mutableEvents.append(event)
        self.sortEvents()
    }

    func replaceEvent(event: Event, atIndex index: Int? = nil) throws {
        guard let index = index ?? self.indexOfEvent(event) else {
            throw EventManagerError.EventNotFound
        }
        self.mutableEvents.removeAtIndex(index)
        self.mutableEvents.append(event)
        self.sortEvents()
    }

    private func indexOfEvent(event: Event) -> Int? {
        return self.mutableEvents.indexOf { $0.identifier.isEqual(event.identifier) }
    }

    private func postSaveNotificationForEvent(event: Event) {
        var userInfo: [String: AnyObject] = [:]
        userInfo[TypeKey] = EKEntityType.Event.rawValue
        userInfo[DataKey] = event
        NSNotificationCenter.defaultCenter()
            .postNotificationName(EntitySaveOperationNotification, object: self, userInfo: userInfo)
    }

    private func sortEvents() {
        self.mutableEvents.sortInPlace() { event, other in
            return event.compareStartDateWithEvent(other) == NSComparisonResult.OrderedAscending
        }
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