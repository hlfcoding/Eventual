//
//  EventManager.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import EventKit

enum EventManagerError: ErrorType {

    case CalendarsNotFound
    case EventAlreadyExists(Int)
    case EventNotFound

}

// MARK: Access Notification

enum EntityAccessResult {

    case Denied, Error, Granted

}

final class EntityAccessPayload: NotificationPayload {

    let type: EKEntityType = .Event
    let result: EntityAccessResult!
    var accessError: NSError?

    init(result: EntityAccessResult) {
        self.result = result
    }
    
}

// MARK: Update Notification

typealias PresavePayloadData = (event: Event, fromIndexPath: NSIndexPath?, toIndexPath: NSIndexPath?)

final class EntityUpdatedPayload: NotificationPayload {

    let type: EKEntityType = .Event
    let event: Event?
    let presave: PresavePayloadData!

    init(event: Event?, presave: PresavePayloadData) {
        self.event = event
        self.presave = presave
    }

}

final class EventManager {

    var store: EKEventStore!

    private var operationQueue: NSOperationQueue!

    private var calendars: [EKCalendar]?
    private var calendar: EKCalendar?

    /**
     Stores wrapped, fetched events in memory for faster access.
     */
    private var mutableEvents: [Event]!
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

    init(events: [Event] = []) {
        self.store = EKEventStore()
        self.operationQueue = NSOperationQueue()

        self.mutableEvents = events
    }

    func completeSetupIfNeeded() {
        guard self.calendar == nil else { return }
        self.store.requestAccessToEntityType(.Event) { granted, accessError in
            var payload: EntityAccessPayload?
            if granted {
                payload = EntityAccessPayload(result: .Granted)
                self.calendars = self.store.calendarsForEntityType(.Event)
                self.calendar = self.store.defaultCalendarForNewEvents
            } else if !granted {
                payload = EntityAccessPayload(result: .Denied)
            } else if let accessError = accessError {
                payload = EntityAccessPayload(result: .Error)
                payload!.accessError = accessError
            }
            NSNotificationCenter.defaultCenter()
                .postNotificationName(EntityAccessNotification, object: self, userInfo: payload?.userInfo)
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
            let normalizedStartDate = startDate.dayDate, normalizedEndDate = endDate.dayDate
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

    func removeEvent(event: Event) throws {
        do {
            let snapshot = Event(entity: event.entity, snapshot: true)
            var fromIndexPath: NSIndexPath?
            if let monthsEvents = self.monthsEvents {
                fromIndexPath = monthsEvents.indexPathForDayOfDate(snapshot.startDate)
            }

            try self.store.removeEvent(event.entity, span: .ThisEvent, commit: true)

            try self.deleteEvent(event)
            self.updateEventsByMonthsAndDays()

            self.postUpdateNotificationForEvent(nil, presave: (snapshot, fromIndexPath, nil))
        }
    }

    func saveEvent(event: Event) throws {
        do {
            self.prepareEvent(event)
            try self.validateEvent(event)

            let snapshot = Event(entity: event.entity, snapshot: true)
            var fromIndexPath: NSIndexPath?, toIndexPath: NSIndexPath?
            if let monthsEvents = self.monthsEvents {
                fromIndexPath = monthsEvents.indexPathForDayOfDate(snapshot.startDate)
                toIndexPath = monthsEvents.indexPathForDayOfDate(event.startDate)
            }

            event.commitChanges()

            try self.store.saveEvent(event.entity, span: .ThisEvent, commit: true)

            do {
                try self.addEvent(event)

            } catch EventManagerError.EventAlreadyExists(let index) {
                try self.replaceEvent(event, atIndex: index)
            }
            self.updateEventsByMonthsAndDays()

            self.postUpdateNotificationForEvent(event, presave: (snapshot, fromIndexPath, toIndexPath))
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

    func deleteEvent(event: Event) throws {
        guard let index = self.indexOfEvent(event) else {
            throw EventManagerError.EventNotFound
        }
        self.mutableEvents.removeAtIndex(index)
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

    private func postUpdateNotificationForEvent(event: Event?, presave: PresavePayloadData) {
        let userInfo = EntityUpdatedPayload(event: event, presave: presave).userInfo
        NSNotificationCenter.defaultCenter()
            .postNotificationName(EntityUpdateOperationNotification, object: self, userInfo: userInfo)
    }

    private func sortEvents() {
        guard !self.mutableEvents.isEmpty else { return }
        self.mutableEvents = self.mutableEvents.sort { event, other in
            return event.compareStartDateWithEvent(other) == NSComparisonResult.OrderedAscending
        }
    }

}

// MARK: - Validation

extension EventManager {

    func validateEvent(event: Event) throws {
        var userInfo: ValidationResults = [
            NSLocalizedDescriptionKey: t("Event is invalid", "error"),
            NSLocalizedRecoverySuggestionErrorKey: t("Please make sure event is filled in.", "error")
        ]
        var failureReason: [String] = []
        if event.title.isEmpty {
            failureReason.append(t("Event title is required.", "error"))
        }
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason.joinWithSeparator(" ")
        let isValid = failureReason.isEmpty
        if !isValid {
            throw NSError(domain: ErrorDomain, code: ErrorCode.InvalidObject.rawValue, userInfo: userInfo)
        }
    }

}