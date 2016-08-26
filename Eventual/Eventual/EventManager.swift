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

// MARK: Fetch Notification

enum EntitiesFetched {

    case UpcomingEvents

}

final class EntitiesFetchedPayload: NotificationPayload {

    let type: EKEntityType = .Event
    let fetchType: EntitiesFetched!

    init(fetchType: EntitiesFetched) {
        self.fetchType = fetchType
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
    var events: NSArray { return mutableEvents as NSArray }

    /**
     Structured events collection to use as UI data source.
     */
    private(set) var monthsEvents: MonthsEvents?

    func updateEventsByMonthsAndDays() {
        monthsEvents = MonthsEvents(events: mutableEvents)
    }

    static var defaultManager: EventManager {
        return AppDelegate.sharedDelegate.eventManager
    }

    // MARK: - Initializers

    init(events: [Event] = []) {
        store = EKEventStore()
        operationQueue = NSOperationQueue()

        mutableEvents = events
    }

    func requestAccessIfNeeded() -> Bool {
        guard calendar == nil else { return false }
        store.requestAccessToEntityType(.Event) { granted, accessError in
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
        return true
    }

}

// MARK: - CRUD

extension EventManager {

    func fetchEventsFromDate(startDate: NSDate = NSDate(),
                             untilDate endDate: NSDate,
                             completion: () -> Void) throws -> NSOperation {
        guard let calendars = calendars else { throw EventManagerError.CalendarsNotFound }

        let predicate: NSPredicate = {
            let normalizedStartDate = startDate.dayDate, normalizedEndDate = endDate.dayDate
            return store.predicateForEventsWithStartDate(
                normalizedStartDate, endDate: normalizedEndDate, calendars: calendars
            )
            }()

        let fetchOperation = NSBlockOperation { [unowned self] in
            self.mutableEvents = self.store.eventsMatchingPredicate(predicate).map { Event(entity: $0) }
            self.sortEvents()
            self.updateEventsByMonthsAndDays()
        }
        fetchOperation.queuePriority = NSOperationQueuePriority.VeryHigh
        let completionOperation = NSBlockOperation { [unowned self] in
            completion()
            let userInfo = EntitiesFetchedPayload(fetchType: .UpcomingEvents).userInfo
            NSNotificationCenter.defaultCenter().postNotificationName(
                EntityFetchOperationNotification, object: self, userInfo: userInfo)
        }
        completionOperation.addDependency(fetchOperation)
        operationQueue.addOperation(fetchOperation)
        NSOperationQueue.mainQueue().addOperation(completionOperation)
        return fetchOperation
    }

    func removeEvent(event: Event) throws {
        do {
            try store.removeEvent(event.entity, span: .ThisEvent, commit: true)

            try deleteEvent(event)
            updateEventsByMonthsAndDays()
        }
    }

    func saveEvent(event: Event) throws {
        do {
            try store.saveEvent(event.entity, span: .ThisEvent, commit: true)

            do {
                try addEvent(event)

            } catch EventManagerError.EventAlreadyExists(let index) {
                try replaceEvent(event, atIndex: index)
            }
            updateEventsByMonthsAndDays()
        }
    }

    // MARK: Helpers

    func addEvent(event: Event) throws {
        if let index = indexOfEvent(event) {
            throw EventManagerError.EventAlreadyExists(index)
        }
        mutableEvents.append(event)
        sortEvents()
    }

    func deleteEvent(event: Event) throws {
        guard let index = indexOfEvent(event) else {
            throw EventManagerError.EventNotFound
        }
        mutableEvents.removeAtIndex(index)
        sortEvents()
    }

    func replaceEvent(event: Event, atIndex index: Int? = nil) throws {
        guard let index = index ?? indexOfEvent(event) else {
            throw EventManagerError.EventNotFound
        }
        mutableEvents.removeAtIndex(index)
        mutableEvents.append(event)
        sortEvents()
    }

    private func indexOfEvent(event: Event) -> Int? {
        return mutableEvents.indexOf { $0.identifier.isEqual(event.identifier) }
    }

    private func postUpdateNotificationForEvent(event: Event?, presave: PresavePayloadData) {
        let userInfo = EntityUpdatedPayload(event: event, presave: presave).userInfo
        NSNotificationCenter.defaultCenter()
            .postNotificationName(EntityUpdateOperationNotification, object: self, userInfo: userInfo)
    }

    private func sortEvents() {
        guard !mutableEvents.isEmpty else { return }
        mutableEvents = mutableEvents.sort { event, other in
            return event.compareStartDateWithEvent(other) == NSComparisonResult.OrderedAscending
        }
    }

}
