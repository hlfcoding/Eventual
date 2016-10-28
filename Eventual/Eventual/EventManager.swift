//
//  EventManager.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import EventKit

enum EventManagerError: Error {

    case calendarsNotFound
    case eventAlreadyExists(Int)
    case eventNotFound(Event)

}

// MARK: Access Notification

enum EntityAccessResult {

    case denied, error, granted

}

final class EntityAccessPayload: NotificationPayload {

    let type: EKEntityType = .event
    let result: EntityAccessResult!
    var accessError: Error?

    init(result: EntityAccessResult) {
        self.result = result
    }

}

// MARK: Fetch Notification

enum EntitiesFetched {

    case upcomingEvents

}

final class EntitiesFetchedPayload: NotificationPayload {

    let type: EKEntityType = .event
    let fetchType: EntitiesFetched!

    init(fetchType: EntitiesFetched) {
        self.fetchType = fetchType
    }

}

// MARK: Update Notification

typealias PresavePayloadData = (event: Event, fromIndexPath: IndexPath?, toIndexPath: IndexPath?)

final class EntityUpdatedPayload: NotificationPayload {

    let type: EKEntityType = .event
    let event: Event?
    let presave: PresavePayloadData!

    init(event: Event?, presave: PresavePayloadData) {
        self.event = event
        self.presave = presave
    }

}

final class EventManager {

    var store: EKEventStore!

    fileprivate var operationQueue: OperationQueue!

    fileprivate var calendars: [EKCalendar]?
    fileprivate var calendar: EKCalendar?

    /**
     Stores wrapped, fetched events in memory for faster access.
     */
    fileprivate var mutableEvents: [Event]!
    var events: NSArray { return mutableEvents as NSArray }

    /**
     Structured events collection to use as UI data source.
     */
    fileprivate(set) var monthsEvents: MonthsEvents?

    func updateEventsByMonthsAndDays() {
        monthsEvents = MonthsEvents(events: mutableEvents)
    }

    // MARK: - Initializers

    init(events: [Event] = []) {
        store = EKEventStore()
        operationQueue = OperationQueue()

        mutableEvents = events
    }

    func requestAccessIfNeeded() -> Bool {
        guard calendar == nil else { return false }
        store.requestAccess(to: .event) { granted, accessError in
            var payload: EntityAccessPayload?
            if granted {
                payload = EntityAccessPayload(result: .granted)
                self.loadCalendars()
            } else if !granted {
                payload = EntityAccessPayload(result: .denied)
            } else if let accessError = accessError {
                payload = EntityAccessPayload(result: .error)
                payload!.accessError = accessError
            }
            NotificationCenter.default.post(
                name: .EntityAccess, object: self, userInfo: payload?.userInfo
            )
        }
        return true
    }

    private func loadCalendars() {
        calendars = store.calendars(for: .event).filter {
            let isSystem = !$0.allowsContentModifications
            guard $0.type != .calDAV || !isSystem else { return false }
            return true
        }
        // TODO: Handle no calendars.
        calendar = store.defaultCalendarForNewEvents
    }

}

// MARK: - CRUD

extension EventManager {

    func fetchEvents(from startDate: Date, until endDate: Date,
                     completion: @escaping ([Event]) -> Void) -> Operation {
        let predicate = store.predicateForEvents(
            withStart: startDate.dayDate, end: endDate.dayDate, calendars: calendars!
        )
        var events: [Event]!
        let fetchOperation = BlockOperation { [unowned self] in
            events = self.store.events(matching: predicate).map { Event(entity: $0) }
        }
        fetchOperation.queuePriority = .veryHigh
        let completionOperation = BlockOperation {
            completion(events)
        }
        completionOperation.addDependency(fetchOperation)
        operationQueue.addOperation(fetchOperation)
        OperationQueue.main.addOperation(completionOperation)
        return fetchOperation
    }

    func remove(events: [Event]) throws {
        do {
            var removedEvents = [Event]()
            try events.forEach() {
                try store.remove($0.entity, span: .thisEvent, commit: true)
                removedEvents.append($0)
            }

            try delete(events: removedEvents)
            updateEventsByMonthsAndDays()
        }
    }

    func save(event: Event) throws {
        do {
            try store.save(event.entity, span: .thisEvent, commit: true)

            do {
                try add(event: event)

            } catch EventManagerError.eventAlreadyExists(let index) {
                try replace(event: event, at: index)
            }
            updateEventsByMonthsAndDays()
        }
    }

    // MARK: Helpers

    func newEvent() -> Event {
        let event = Event(entity: EKEvent(eventStore: store))
        event.calendar = calendar!
        return event
    }

    func add(event: Event) throws {
        if let index = indexOf(event: event) {
            throw EventManagerError.eventAlreadyExists(index)
        }
        mutableEvents.append(event)
        sortEvents()
    }

    func delete(events: [Event]) throws {
        try events.forEach() {
            guard let index = indexOf(event: $0) else {
                throw EventManagerError.eventNotFound($0)
            }
            mutableEvents.remove(at: index)
        }
        sortEvents()
    }

    func replace(event: Event, at index: Int? = nil) throws {
        guard let index = index ?? indexOf(event: event) else {
            throw EventManagerError.eventNotFound(event)
        }
        mutableEvents.remove(at: index)
        mutableEvents.append(event)
        sortEvents()
    }

    private func indexOf(event: Event) -> Int? {
        return mutableEvents.index { $0.identifier.isEqual(event.identifier) }
    }

    private func sortEvents() {
        guard !mutableEvents.isEmpty else { return }
        mutableEvents = mutableEvents.sorted { event, other in
            return event.compareStartDate(with: other) == ComparisonResult.orderedAscending
        }
    }

}
