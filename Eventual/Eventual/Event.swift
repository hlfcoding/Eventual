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

    private enum SupportedEntityKey: String {
        case AllDay = "allDay"
        case StartDate = "startDate"
        case EndDate = "endDate"
        case Calendar = "calendar"
        case Title = "title"
        case Location = "location"

        private static let bySetOrder: [SupportedEntityKey] = [.AllDay, .StartDate, .EndDate, .Calendar, .Title, .Location]
    }

    /**
     Wraps access to this `EKEvent` but only for used accessors.
     */
    private(set) var entity: EKEvent!
    /**
     Internally mutable only for testing.
     */
    var isNew = true

    private var changes = UserInfo()
    private var isSnapshot = false

    // MARK: Accessors

    var identifier: String { return entity.eventIdentifier }
    var startDate: NSDate {
        get {
            return hasChangeForKey(.StartDate) ? (changeForKey(.StartDate) as! NSDate) : entity.startDate
        }
        set(newValue) {
            addChangeToKey(.StartDate, value: newValue)
        }
    }
    var endDate: NSDate {
        get {
            return hasChangeForKey(.EndDate) ? (changeForKey(.EndDate) as! NSDate) : entity.endDate
        }
        set(newValue) {
            addChangeToKey(.EndDate, value: newValue)
        }
    }
    var allDay: Bool {
        get {
            return hasChangeForKey(.AllDay) ? (changeForKey(.AllDay) as! Bool) : entity.allDay
        }
        set(newValue) {
            addChangeToKey(.AllDay, value: newValue)
        }
    }

    var calendar: EKCalendar {
        get {
            return hasChangeForKey(.Calendar) ? (changeForKey(.Calendar) as! EKCalendar) : entity.calendar
        }
        set(newValue) {
            addChangeToKey(.Calendar, value: newValue)
        }
    }
    var title: String {
        get {
            return hasChangeForKey(.Title) ? (changeForKey(.Title) as! String) : entity.title
        }
        set(newValue) {
            addChangeToKey(.Title, value: newValue)
        }
    }
    var location: String? {
        get {
            return hasChangeForKey(.Location) ? (changeForKey(.Location) as? String) : entity.location
        }
        set(newValue) {
            addChangeToKey(.Location, value: newValue)
        }
    }

    private func changeForKey(entityKey: SupportedEntityKey) -> AnyObject? {
        return changes[entityKey.rawValue]
    }

    private func hasChangeForKey(entityKey: SupportedEntityKey, forced: Bool = false) -> Bool {
        guard forced || !isSnapshot else { return true }
        return changes[entityKey.rawValue] != nil
    }

    private func addChangeToKey(entityKey: SupportedEntityKey, value: AnyObject?, forced: Bool = false) {
        guard forced || !isSnapshot else { return }
        changes[entityKey.rawValue] = value
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
            SupportedEntityKey.bySetOrder.forEach { key in
                addChangeToKey(key, value: entity.valueForKey(key.rawValue), forced: true)
            }
            isNew = entity.eventIdentifier.isEmpty

        } else {
            self.entity = entity
            isNew = identifier.isEmpty
        }
    }

    // MARK: Change API

    /**
     For when passing in a new `EKEvent` and it needs a valid start date.
     - parameter date: Defaults to start of today.
     */
    func start(date: NSDate = NSDate().dayDate) {
        addChangeToKey(.StartDate, value: date)
        commitChanges()
    }

    /**
     Transfers changed values to the actual `entity`. Then calls `resetChanges`.
     */
    func commitChanges() {
        guard !isSnapshot else { return }
        SupportedEntityKey.bySetOrder.forEach { key in
            guard let change = changeForKey(key) else { return }
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

    func compareStartDateWithEvent(other: Event) -> NSComparisonResult {
        return startDate.compare(other.startDate)
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
        guard let location = location where !location.isEmpty else { return false }
        return true
    }

    /**
     Addition. `EKEvent` doesn't store location as a `CLPlacemark`, much less an `MKMapItem`.
     Additional geocoding with the address string is needed to get matching `CLPlacemark`(s).
     */
    func fetchLocationMapItemIfNeeded(completionHandler: (MKMapItem?, NSError?) -> Void) {
        guard hasLocation else { return }

        // TODO: Throw for rate-limiting and handle those exceptions.
        CLGeocoder().geocodeAddressString(location!) { placemarks, error in
            guard error == nil else { return completionHandler(nil, error) }
            guard let placemark = placemarks?.first else { return completionHandler(nil, nil) } // Location could not be geocoded.
            completionHandler(MKMapItem(placemark: MKPlacemark(placemark: placemark)), nil)
        }
    }

}
