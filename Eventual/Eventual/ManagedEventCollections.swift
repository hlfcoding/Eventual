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

}

class UpcomingEvents: ManagedEventCollection {

    var isInvalid = true
    fileprivate(set) var events: MonthsEvents?

    private(set) var fetchCursor: Date?
    private let fetchRangeComponents = DateComponents(month: 6)
    private var isFetching = false

    func fetch(completion: (() -> Void)?) -> Operation? {
        guard !isFetching else { return nil }
        isFetching = true

        let startDate = isInvalid ? Date() : fetchCursor!
        let endDate = Calendar.current.date(byAdding: fetchRangeComponents, to: startDate)!

        return manager.fetchEvents(from: startDate, until: endDate) { events in
            self.isFetching = false
            self.fetchCursor = endDate
            self.update(events: events)

            completion?()
            let userInfo = EntitiesFetchedPayload(fetchType: .upcomingEvents).userInfo
            NotificationCenter.default.post(
                name: .EntityFetchOperation, object: self, userInfo: userInfo
            )
        }
    }

    func sort() {
        guard !mutableEvents.isEmpty else { return }
        mutableEvents = mutableEvents.sorted {
            return $0.compareStartDate(with: $1) == ComparisonResult.orderedAscending
        }
    }

    func update(events: [Event]) {
        if isInvalid {
            isInvalid = false
            mutableEvents = events
        } else {
            mutableEvents.append(contentsOf: events)
        }
        sort()
        self.events = MonthsEvents(events: mutableEvents)
    }

}
