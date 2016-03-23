//
//  EventCollections.swift
//  Eventual
//
//  Created by Peng Wang on 2/10/16.
//  Copyright (c) 2016 Eventual App. All rights reserved.
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

    private func dayForEvent(event: Event) -> NSDate {
        return self.addDateIfNeeded(event.startDate.dayDate)
    }

    private func eventsForDay(day: NSDate) -> NSMutableArray {
        var events = self.eventsForDate(day)
        if events == nil {
            events = NSMutableArray()
            self.events.addObject(events!)
        }
        return events as! NSMutableArray
    }

    /**
     Takes user-provided `date`, not guaranteed valid.
     */
    func eventsForDayOfDate(date: NSDate) -> DayEvents? {
        return self.eventsForDate(date.dayDate) as? NSMutableArray
    }

}

class MonthsEvents: EventsByDate {

    var months: NSMutableArray { return self.dates }

    init(events: [Event]) {
        super.init()

        for event in events {
            let month = self.monthForEvent(event)
            let monthEvents = self.eventsForMonth(month)
            let day = monthEvents.dayForEvent(event)
            let dayEvents = monthEvents.eventsForDay(day)
            // This is why Swift arrays (assign by value) won't work.
            dayEvents.addObject(event)
        }
    }

    private func monthForEvent(event: Event) -> NSDate {
        return self.addDateIfNeeded(event.startDate.monthDate)
    }

    private func eventsForMonth(month: NSDate) -> MonthEvents {
        var events = self.eventsForDate(month)
        if events == nil {
            events = MonthEvents()
            self.events.addObject(events!)
        }
        return events as! MonthEvents
    }

    /**
     Takes user-provided `date`, not guaranteed valid.
     */
    func eventsForMonthOfDate(date: NSDate) -> MonthEvents? {
        return self.eventsForDate(date.monthDate) as? MonthEvents
    }

    /**
     Takes user-provided `date`, not guaranteed valid.
     */
    func eventsForDayOfDate(date: NSDate) -> DayEvents? {
        return self.eventsForMonthOfDate(date)?.eventsForDayOfDate(date)
    }

    // MARK: NSIndexPath

    private func eventsForMonthAtIndexPath(indexPath: NSIndexPath) -> MonthEvents? {
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

    func indexPathForDayOfDate(date: NSDate) -> NSIndexPath? {
        let monthIndex = self.months.indexOfObject(date.monthDate)
        guard monthIndex != NSNotFound,
              let dayIndex = self.daysForMonthAtIndex(monthIndex)?.indexOfObject(date.dayDate)
              where dayIndex != NSNotFound
              else { return nil }
        return NSIndexPath(forItem: dayIndex, inSection: monthIndex)
    }

}
