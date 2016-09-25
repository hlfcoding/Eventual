//
//  Event.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import EventKit

/**
 A wrapper around `EKEvent` (for now) that makes up for the latter's shortcomings: inability to be
 easily copied but also lacking a staging area for changes before 'committing' them. There's
 `EKObject`'s `hasChanges`, `reset`, and `rollback`, but the app would still be modifying an event
 that's essentially shared state.
 */
class Event: NSObject {

    private enum EntityKey: String {
        case isAllDay = "isAllDay"
        case startDate = "startDate"
        case endDate = "endDate"
        case calendar = "calendar"
        case title = "title"
        case location = "location"

        static let bySetOrder: [EntityKey] = [.isAllDay, .startDate, .endDate, .calendar, .title, .location]
    }

    /**
     Wraps access to this `EKEvent` but only for used accessors.
     */
    private(set) var entity: EKEvent!
    /**
     Internally mutable only for testing.
     */
    var isNew = true

    private var changes = [EntityKey: Any]()
    private var isSnapshot = false

    // MARK: Accessors

    var identifier: String { return entity.eventIdentifier }
    var startDate: Date {
        get {
            return isChanged(.startDate) ? (changes[.startDate] as! Date) : entity.startDate
        }
        set(newValue) {
            setChange(.startDate, value: newValue)
        }
    }
    var endDate: Date {
        get {
            return isChanged(.endDate) ? (changes[.endDate] as! Date) : entity.endDate
        }
        set(newValue) {
            setChange(.endDate, value: newValue)
        }
    }
    var isAllDay: Bool {
        get {
            return isChanged(.isAllDay) ? (changes[.isAllDay] as! Bool) : entity.isAllDay
        }
        set(newValue) {
            setChange(.isAllDay, value: newValue)
        }
    }

    var calendar: EKCalendar {
        get {
            return isChanged(.calendar) ? (changes[.calendar] as! EKCalendar) : entity.calendar
        }
        set(newValue) {
            setChange(.calendar, value: newValue)
        }
    }
    var title: String {
        get {
            return isChanged(.title) ? (changes[.title] as! String) : entity.title
        }
        set(newValue) {
            setChange(.title, value: newValue)
        }
    }
    var location: String? {
        get {
            return isChanged(.location) ? (changes[.location] as? String) : entity.location
        }
        set(newValue) {
            setChange(.location, value: newValue)
        }
    }

    private func isChanged(_ entityKey: EntityKey, forced: Bool = false) -> Bool {
        guard forced || !isSnapshot else { return true }
        return changes[entityKey] != nil
    }

    private func setChange<T>(_ entityKey: EntityKey, value: T?, forced: Bool = false) {
        guard forced || !isSnapshot else { return }
        changes[entityKey] = value
    }

    // MARK: Initializers

    /**
     Creates either an event with a backing `entity` or a `snapshot`.
     - parameter entity: If `snapshot` is true, this can't be a 'new' event.
     - parameter snapshot: Defaults to `false`.
     */
    init(entity: EKEvent, snapshot: Bool = false) {
        super.init()

        if snapshot {
            isSnapshot = true
            EntityKey.bySetOrder.forEach { key in
                setChange(key, value: entity.value(forKey: key.rawValue), forced: true)
            }
            isNew = entity.eventIdentifier.isEmpty

        } else {
            self.entity = entity
            isNew = identifier.isEmpty
        }
    }

    func snapshot() -> Event {
        return Event(entity: entity, snapshot: true)
    }

    // MARK: Change API

    /**
     For when passing in a new `EKEvent` and it needs a valid start date.
     - parameter date: Defaults to start of today.
     */
    func start(date: Date = Date().dayDate) {
        setChange(.startDate, value: date)
        commitChanges()
    }

    /**
     Transfers changed values to the actual `entity`. Then calls `resetChanges`.
     */
    func commitChanges() {
        guard !isSnapshot else { return }
        EntityKey.bySetOrder.forEach { key in
            guard let change = changes[key] else { return }
            entity.setValue(change, forKey: key.rawValue)
        }
        resetChanges()
    }

    /**
     Reset all changes with this, or just create a new instance.
     */
    func resetChanges() {
        guard !isSnapshot else { return }
        changes = [:]
    }

    // MARK: Proxying

    func compareStartDate(with other: Event) -> ComparisonResult {
        return startDate.compare(other.startDate)
    }

}

// MARK: - Defaults

extension Event {

    func prepare() {
        // Fill some missing blanks.
        if startDate.hasCustomTime {
            isAllDay = false
            endDate = startDate.hourDateFromAddingHours(1)
        } else {
            isAllDay = true
            // EventKit auto-adjusts endDate per allDay.
            endDate = startDate
        }
    }

}

// MARK: - Location

import CoreLocation
import MapKit

extension Event {

    /**
     Addition. Apparently `location` can be initialized as an empty string, so that needs to be
     checked too.
     */
    var hasLocation: Bool {
        guard let location = location, !location.isEmpty else { return false }
        return true
    }

    /**
     Addition. `EKEvent` doesn't store location as a `CLPlacemark`, much less an `MKMapItem`.
     Additional geocoding with the address string is needed to get matching `CLPlacemark`(s).
     */
    func fetchLocationMapItemIfNeeded(completion: @escaping (MKMapItem?, Error?) -> Void) {
        guard hasLocation else { return }

        // TODO: Throw for rate-limiting and handle those exceptions.
        CLGeocoder().geocodeAddressString(location!) { placemarks, error in
            guard error == nil else { return completion(nil, error) }
            guard let placemark = placemarks?.first else { return completion(nil, nil) } // Location could not be geocoded.
            completion(MKMapItem(placemark: MKPlacemark(placemark: placemark)), nil)
        }
    }

}

// MARK: - Validation

extension Event {

    func validate() throws {
        var userInfo: ValidationResults = [
            NSLocalizedDescriptionKey: t("Event is invalid", "error"),
            NSLocalizedRecoverySuggestionErrorKey: t("Please make sure event is filled in.", "error"),
            ]
        var failureReason: [String] = []
        if title.isEmpty {
            failureReason.append(t("Event title is required.", "error"))
        }
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason.joined(separator: " ")
        let isValid = failureReason.isEmpty
        if !isValid {
            throw NSError(domain: ErrorDomain, code: ErrorCode.InvalidObject.rawValue, userInfo: userInfo)
        }
    }

}
