//
//  Event.swift
//  Eventual
//
//  Created by Peng Wang on 2/10/16.
//  Copyright © 2016 Eventual App. All rights reserved.
//

import EventKit

class Event: NSObject {

    static let supportedEntityKeys = ["startDate", "endDate", "allDay", "calendar", "title", "location"]

    /**
     Wraps access to this `EKEvent` but only for used accessors.
     */
    private(set) var entity: EKEvent!

    var isNew: Bool {
        guard !self.isSnapshot else { return false }
        return self.identifier.isEmpty
    }

    private var changes = [String: AnyObject]()
    private var isSnapshot = false

    var identifier: String { return self.entity.eventIdentifier }
    var startDate: NSDate {
        get { return hasChangeForKey("startDate") ? (changes["startDate"] as! NSDate) : entity.startDate }
        set(newValue) { addChangeToKey("startDate", value: newValue) }
    }
    var endDate: NSDate {
        get { return hasChangeForKey("endDate") ? (changes["endDate"] as! NSDate) : entity.endDate }
        set(newValue) { addChangeToKey("endDate", value: newValue) }
    }
    var allDay: Bool {
        get { return hasChangeForKey("allDay") ? (changes["allDay"] as! Bool) : entity.allDay }
        set(newValue) { addChangeToKey("allDay", value: newValue) }
    }

    var calendar: EKCalendar {
        get { return hasChangeForKey("calendar") ? (changes["calendar"] as! EKCalendar) : entity.calendar }
        set(newValue) { addChangeToKey("calendar", value: newValue) }
    }
    var title: String {
        get { return hasChangeForKey("title") ? (changes["title"] as! String) : entity.title }
        set(newValue) { addChangeToKey("title", value: newValue) }
    }
    var location: String? {
        get { return hasChangeForKey("location") ? (changes["location"] as? String) : entity.location }
        set(newValue) { addChangeToKey("location", value: newValue) }
    }

    private func hasChangeForKey(entityKey: String) -> Bool {
        guard !self.isSnapshot else { return true }
        return changes[entityKey] != nil
    }

    private func addChangeToKey(entityKey: String, value: AnyObject?) {
        guard !self.isSnapshot else { return }
        self.changes[entityKey] = value
    }

    init(entity: EKEvent, snapshot: Bool = false) {
        super.init()

        if snapshot {
            self.isSnapshot = true
            Event.supportedEntityKeys.forEach { key in
                self.changes[key] = entity.valueForKey(key)
            }
        } else {
            self.entity = entity
        }
    }

    func commitChanges() {
        guard !self.isSnapshot else { return }
        Event.supportedEntityKeys.forEach { key in
            guard let change = self.changes[key] else { return }
            self.entity.setValue(change, forKey: key)
        }
        self.resetChanges()
    }

    func resetChanges() {
        guard !self.isSnapshot else { return }
        self.changes = [String: AnyObject]()
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
        guard let location = self.location where !location.isEmpty else { return false }
        return true
    }

    /**
     Addition. `EKEvent` doesn't store location as a `CLPlacemark`, much less an `MKMapItem`.
     Additional geocoding with the address string is needed to get matching `CLPlacemark`(s).
     */
    func fetchLocationPlacemarkIfNeeded(completionHandler: CLGeocodeCompletionHandler) {
        guard self.hasLocation else { return }

        // TODO: Throw for rate-limiting and handle those exceptions.
        CLGeocoder().geocodeAddressString(self.location!, completionHandler: completionHandler)
    }

}