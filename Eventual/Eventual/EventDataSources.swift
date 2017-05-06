//
//  EventDataSources.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import EventKit

enum EventCollectionError: Error {

    case notFound(Event)

}

final class EntitiesFetchedPayload: NotificationPayload {

    let type: EKEntityType = .event

}

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

class EventDataSource {

    /**
     Stores wrapped, fetched events in memory for faster access.
     */
    fileprivate var mutableEvents = [Event]()
    fileprivate var sortOrder: ComparisonResult!
    private(set) weak var store: EventStore!

    var isEmpty: Bool { return mutableEvents.isEmpty }

    init(store: EventStore) {
        self.store = store
        sortOrder = .orderedAscending
    }

    func findEvent(identifier: String) -> Event? {
        return mutableEvents.first() { $0.identifier == identifier }
    }

    fileprivate func indexOf(event: Event) -> Int? {
        return mutableEvents.index { $0.identifier == event.identifier }
    }

    fileprivate func notify(name: Notification.Name, payload: NotificationPayload) {
        NotificationCenter.default.post(name: name, object: self, userInfo: payload.userInfo)
    }

    func refresh() {
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
            return $0.compareStartDate(with: $1) == self.sortOrder
        }
    }

}

class MonthEventDataSource: EventDataSource {

    fileprivate(set) var events: MonthsEvents?

    var isInvalid = true

    fileprivate(set) var fetchCursor: Date?
    fileprivate(set) var fetchOperation: Operation?
    fileprivate var fetchRangeComponents: DateComponents!
    fileprivate var isFetching = false

    var wasStoreChanged = false
    var wasTimeChanged = false
    fileprivate var storeChangeObserver: NSObjectProtocol?
    fileprivate var timeChangeObserver: NSObjectProtocol?

    var isNeedsRefreshEnabled: Bool = false {
        didSet {
            guard isNeedsRefreshEnabled != oldValue else { return }
            let center = NotificationCenter.default
            if isNeedsRefreshEnabled {
                storeChangeObserver = center.addObserver(
                    forName: .EKEventStoreChanged, object: nil, queue: .main
                ) { [unowned self] _ in
                    self.wasStoreChanged = true
                }
                timeChangeObserver = center.addObserver(
                    forName: .UIApplicationSignificantTimeChange, object: nil, queue: .main
                ) { [unowned self] _ in
                    self.wasTimeChanged = true
                }
            } else {
                wasStoreChanged = false
                wasTimeChanged = false
                center.removeObserver(storeChangeObserver!)
                center.removeObserver(timeChangeObserver!)
            }
        }
    }

    func refreshIfNeeded() {
        if wasStoreChanged {
            refetch()
        } else if wasTimeChanged, !isEmpty {
            refetch()
            notifyOfFetch()
        }
    }

    override func refresh() {
        super.refresh()
        events = MonthsEvents(events: mutableEvents)
    }

    fileprivate func beginFetch() -> Bool {
        guard !isFetching else { return false }
        isFetching = true
        return true
    }

    fileprivate func endFetch(events: [Event], completion: (() -> Void)? = nil) {
        isFetching = false
        update(events: events)
        completion?()
        notifyOfFetch()
    }

    func fetch(completion: (() -> Void)? = nil) {
        preconditionFailure("Unimplemented method.")
    }

    func notifyOfFetch() {
        preconditionFailure("Unimplemented method.")
    }

    func refetch(completion: (() -> Void)? = nil) {
        isInvalid = true
        fetch(completion: completion)
    }

    func remove(dayEvents: [Event]) throws {
        try store.remove(events: dayEvents)
        try dayEvents.forEach() { try remove(event: $0) }
        refresh()
    }

    func remove(event: Event, commit: Bool) throws {
        let snapshot = Event(entity: event.entity, snapshot: true)
        let fromIndexPath = events!.indexPathForDay(of: snapshot.startDate)
        if commit {
            try store.remove(events: [event])
        }
        try remove(event: event)
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
            try store.save(event: event)
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

class PastEvents: MonthEventDataSource {

    override init(store: EventStore) {
        super.init(store: store)
        fetchRangeComponents = DateComponents(year: -1)
        sortOrder = .orderedDescending
    }

    override func fetch(completion: (() -> Void)? = nil) {
        guard beginFetch() else { return }

        let endDate = isInvalid ? Date() : fetchCursor!
        let startDate = Calendar.current.date(byAdding: fetchRangeComponents, to: endDate)!

        fetchOperation = store.fetchEvents(from: startDate, until: endDate) { events in
            self.fetchCursor = startDate
            self.endFetch(events: events, completion: completion)
        }
    }

    override func notifyOfFetch() {
        notify(name: .EntityFetchOperation, payload: EntitiesFetchedPayload())
    }

}

class UpcomingEvents: MonthEventDataSource {

    override init(store: EventStore) {
        super.init(store: store)
        fetchRangeComponents = DateComponents(month: 6)
    }

    override func fetch(completion: (() -> Void)? = nil) {
        guard beginFetch() else { return }

        let startDate = isInvalid ? Date() : fetchCursor!
        let endDate = Calendar.current.date(byAdding: fetchRangeComponents, to: startDate)!

        fetchOperation = store.fetchEvents(from: startDate, until: endDate) { events in
            self.fetchCursor = endDate
            self.endFetch(events: events, completion: completion)
        }
    }

    override func notifyOfFetch() {
        notify(name: .EntityFetchOperation, payload: EntitiesFetchedPayload())
    }

}
