//
//  EventCollections.swift
//  Eventual
//
//  Created by Peng Wang on 2/10/16.
//  Copyright © 2016 Eventual App. All rights reserved.
//

import EventKit

typealias DayEvents = NSArray

class EventsByDate {

    let dates: NSMutableArray = []
    let events: NSMutableArray = []

    private func addDateIfNeeded(date: NSDate) -> NSDate {
        if self.dates.indexOfObject(date) == NSNotFound {
            self.dates.addObject(date)
        }
        return date
    }

    private func eventsForDate(date: NSDate) -> AnyObject? {
        let index = self.dates.indexOfObject(date)
        guard index != NSNotFound && self.events.count > index else { return nil }
        return self.events[index]
    }

}

class MonthEvents: EventsByDate {

    var days: NSMutableArray { return self.dates }

    func dayForEvent(event: NSObject) -> NSDate? {
        guard let date = event.valueForKey("startDate") as? NSDate else { return nil }
        return self.addDateIfNeeded(date.dayDate!)
    }

    func eventsForDay(day: NSDate) -> NSMutableArray {
        var events = self.eventsForDate(day)
        if events == nil {
            events = NSMutableArray()
            self.events.addObject(events!)
        }
        return events as! NSMutableArray
    }

    /**
     @param date User-provided date, not guaranteed valid.
     */
    func eventsForDayOfDate(date: NSDate) -> DayEvents? {
        guard let day = date.dayDate else { return nil }
        return self.eventsForDay(day)
    }

}

class MonthsEvents: EventsByDate {

    var months: NSMutableArray { return self.dates }

    init(events: [NSObject]) {
        super.init()

        for event in events {
            guard let month = self.monthForEvent(event) else { continue }
            let monthEvents = self.eventsForMonth(month)
            guard let day = monthEvents.dayForEvent(event) else { continue }
            let dayEvents = monthEvents.eventsForDay(day)
            // This is why Swift arrays (assign by value) won't work.
            dayEvents.addObject(event)
        }
    }

    func monthForEvent(event: NSObject) -> NSDate? {
        guard let date = event.valueForKey("startDate") as? NSDate else { return nil }
        return self.addDateIfNeeded(date.monthDate!)
    }

    func eventsForMonth(month: NSDate) -> MonthEvents {
        var events = self.eventsForDate(month)
        if events == nil {
            events = MonthEvents()
            self.events.addObject(events!)
        }
        return events as! MonthEvents
    }

    /**
     @param date User-provided date, not guaranteed valid.
     */
    func eventsForMonthOfDate(date: NSDate) -> MonthEvents? {
        guard let month = date.monthDate else { return nil }
        return self.eventsForMonth(month)
    }

    /**
     @param date User-provided date, not guaranteed valid.
     */
    func eventsForDayOfDate(date: NSDate) -> DayEvents? {
        return self.eventsForMonthOfDate(date)?.eventsForDayOfDate(date)
    }

    // MARK: NSIndexPath

    func eventsForMonthAtIndexPath(indexPath: NSIndexPath) -> MonthEvents? {
        guard self.events.count > indexPath.section else { return nil }
        return self.events[indexPath.section] as? MonthEvents
    }

    func daysForMonthAtIndex(index: Int) -> NSArray? {
        guard self.months.count > index else { return nil }
        return (self.events[index] as? MonthEvents)?.days
    }

    func eventsForDayAtIndexPath(indexPath: NSIndexPath) -> DayEvents? {
        let monthEvents = self.eventsForMonthAtIndexPath(indexPath)
        guard monthEvents?.events.count > indexPath.item else { return nil }
        return monthEvents?.events[indexPath.item] as? DayEvents
    }

    func dayAtIndexPath(indexPath: NSIndexPath) -> NSDate? {
        return self.eventsForMonthAtIndexPath(indexPath)?.days[indexPath.item] as? NSDate
    }
    
}
