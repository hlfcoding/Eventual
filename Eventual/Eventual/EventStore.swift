//
//  EventStore.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import EventKit

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

final class EventStore {

    var hasAccess: Bool {
        return calendar != nil
    }

    var store: EKEventStore!

    fileprivate var operationQueue: OperationQueue!

    fileprivate var calendars: [EKCalendar]?
    fileprivate var calendar: EKCalendar?

    // MARK: - Initializers

    init() {
        store = EKEventStore()
        operationQueue = OperationQueue()
    }

    func requestAccess(completion: (() -> Void)? = nil) {
        guard !hasAccess else {
            completion?()
            return
        }
        store.requestAccess(to: .event) { granted, accessError in
            var payload: EntityAccessPayload?
            if granted {
                self.loadCalendars()
                completion?()
                payload = EntityAccessPayload(result: .granted)
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

extension EventStore {

    @discardableResult func fetchEvents(from startDate: Date, until endDate: Date,
                                        completion: @escaping ([Event]) -> Void) -> Operation? {
        guard hasAccess else {
            requestAccess() { self.fetchEvents(from: startDate, until: endDate, completion: completion) }
            return nil
        }
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
        guard hasAccess else {
            requestAccess() { try! self.remove(events: events) }
            return
        }
        try events.forEach() {
            try store.remove($0.entity, span: .thisEvent, commit: true)
        }
    }

    func save(event: Event) throws {
        guard hasAccess else {
            requestAccess() { try! self.save(event: event) }
            return
        }
        try store.save(event.entity, span: .thisEvent, commit: true)
    }

    // MARK: Helpers

    func newEntity() -> EKEvent {
        let entity = EKEvent(eventStore: store)
        entity.calendar = calendar!
        return entity
    }

    func newEvent() -> Event {
        return Event(entity: newEntity())
    }

}
