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
        get { return self.valueForEntityKey("startDate") as! NSDate }
        set(newValue) { self.addChangeToEntityKey("startDate", value: newValue) }
    }
    var endDate: NSDate {
        get { return self.valueForEntityKey("endDate") as! NSDate }
        set(newValue) { self.addChangeToEntityKey("endDate", value: newValue) }
    }
    var allDay: Bool {
        get { return self.valueForEntityKey("allDay") as! Bool }
        set(newValue) { self.addChangeToEntityKey("allDay", value: newValue) }
    }

    var calendar: EKCalendar {
        get { return self.valueForEntityKey("calendar") as! EKCalendar }
        set(newValue) { self.addChangeToEntityKey("calendar", value: newValue) }
    }
    var title: String {
        get { return self.valueForEntityKey("title") as! String }
        set(newValue) { self.addChangeToEntityKey("title", value: newValue) }
    }
    var location: String? {
        get { return self.valueForEntityKey("location") as? String }
        set(newValue) { self.addChangeToEntityKey("location", value: newValue) }
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

    func addChangeToEntityKey(key: String, value: AnyObject?) {
        guard !self.isSnapshot else { return }
        self.changes[key] = value
    }

    func commitChanges() {
        guard !self.isSnapshot else { return }
        Event.supportedEntityKeys.forEach { key in
            guard let change = self.changes[key] else { return }
            self.entity.setValue(change, forKey: key)
        }
    }

    func resetChanges() {
        guard !self.isSnapshot else { return }
        self.changes = [String: AnyObject]()
    }

    func valueForEntityKey(key: String) -> AnyObject? {
        return self.isSnapshot ? self.changes[key] : self.entity.valueForKey(key)
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