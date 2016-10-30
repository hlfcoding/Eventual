//
//  ManagedEventCollections.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import Foundation

class ManagedEventCollection {

    /**
     Stores wrapped, fetched events in memory for faster access.
     */
    fileprivate var mutableEvents = [Event]()
    private(set) weak var manager: EventManager!

    init(manager: EventManager) {
        self.manager = manager
    }

    fileprivate func notify(name: Notification.Name, payload: NotificationPayload) {
        NotificationCenter.default.post(name: name, object: self, userInfo: payload.userInfo)
    }

    fileprivate func refresh() {
        sort()
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
