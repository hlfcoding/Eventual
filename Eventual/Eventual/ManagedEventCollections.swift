//
//  ManagedEventCollections.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import Foundation

enum EventCollectionError: Error {

    case notFound(Event)
    
}

class ManagedEventCollection {

    /**
     Stores wrapped, fetched events in memory for faster access.
     */
    fileprivate var mutableEvents = [Event]()
    private(set) weak var manager: EventManager!

    init(manager: EventManager) {
        self.manager = manager
    }

    fileprivate func indexOf(event: Event) -> Int? {
        return mutableEvents.index { $0.identifier == event.identifier }
    }

    fileprivate func notify(name: Notification.Name, payload: NotificationPayload) {
        NotificationCenter.default.post(name: name, object: self, userInfo: payload.userInfo)
    }

    fileprivate func refresh() {
        sort()
    }

    fileprivate func remove(event: Event) throws {
        guard let index = indexOf(event: event) else { throw EventCollectionError.notFound(event) }
        mutableEvents.remove(at: index)
    }

    fileprivate func save(event: Event) throws {
        if let index = indexOf(event: event) { mutableEvents.remove(at: index) }
        mutableEvents.append(event)
    }

    fileprivate func sort() {
        guard !mutableEvents.isEmpty else { return }
        mutableEvents = mutableEvents.sorted {
            return $0.compareStartDate(with: $1) == ComparisonResult.orderedAscending
        }
    }

}

class UpcomingEvents: ManagedEventCollection {

    var isInvalid = true
    fileprivate(set) var events: MonthsEvents?

    private(set) var fetchCursor: Date?
    private(set) var fetchOperation: Operation?
    private let fetchRangeComponents = DateComponents(month: 6)
    private var isFetching = false

    func fetch(completion: (() -> Void)?) {
        guard !isFetching else { return }
        isFetching = true

        let startDate = isInvalid ? Date() : fetchCursor!
        let endDate = Calendar.current.date(byAdding: fetchRangeComponents, to: startDate)!

        fetchOperation = manager.fetchEvents(from: startDate, until: endDate) { events in
            self.isFetching = false
            self.fetchCursor = endDate
            self.update(events: events)

            completion?()
            self.notify(name: .EntityFetchOperation,
                        payload: EntitiesFetchedPayload(fetchType: .upcomingEvents))
        }
    }

    override fileprivate func refresh() {
        super.refresh()
        events = MonthsEvents(events: mutableEvents)
    }

    func remove(dayEvents: [Event]) throws {
        try manager.remove(events: dayEvents)
        try dayEvents.forEach() { try super.remove(event: $0) }
        refresh()
    }

    func remove(event: Event, commit: Bool) throws {
        let snapshot = Event(entity: event.entity, snapshot: true)
        let fromIndexPath = events!.indexPathForDay(of: snapshot.startDate)
        if commit {
            try manager.remove(events: [event])
        }
        try super.remove(event: event)
        refresh()
        let presave: PresavePayloadData = (snapshot, fromIndexPath, nil)
        notify(name: .EntityUpdateOperation,
               payload: EntityUpdatedPayload(event: nil, presave: presave))
    }

    func save(event: Event, commit: Bool) throws {
        event.prepare()
        try event.validate()
        let snapshot = event.snapshot()
        let fromIndexPath = events!.indexPathForDay(of: snapshot.startDate)
        let toIndexPath = events!.indexPathForDay(of: event.startDate)
        event.commitChanges()
        if commit {
            try manager.save(event: event)
        }
        try super.save(event: event)
        refresh()
        let presave: PresavePayloadData = (snapshot, fromIndexPath, toIndexPath)
        notify(name: .EntityUpdateOperation,
               payload: EntityUpdatedPayload(event: event, presave: presave))
    }

    fileprivate func update(events: [Event]) {
        if isInvalid {
            isInvalid = false
            mutableEvents = events
        } else {
            mutableEvents.append(contentsOf: events)
        }
        refresh()
    }

}
