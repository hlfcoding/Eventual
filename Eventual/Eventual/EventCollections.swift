//
//  EventCollections.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
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

final class MonthEvents: EventsByDate {

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

final class MonthsEvents: EventsByDate {

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

    func monthAtIndex(index: Int) -> NSDate? {
        guard self.months.count > 0 else { return nil }
        return self.months[index] as? NSDate
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

}

// MARK: NSIndexPath

typealias EventWithChangeInfo = (event: Event?, currentIndexPath: NSIndexPath?)
typealias SelectiveUpdatingInfo = (
    deletions: [NSIndexPath], insertions: [NSIndexPath], reloads: [NSIndexPath],
    sectionDeletions: NSIndexSet, sectionInsertions: NSIndexSet
)

extension MonthsEvents {

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
        guard let days = self.eventsForMonthAtIndexPath(indexPath)?.days where days.count > indexPath.item
            else { return nil }
        return days[indexPath.item] as? NSDate
    }

    func indexPathForDayOfDate(date: NSDate) -> NSIndexPath? {
        let monthIndex = self.months.indexOfObject(date.monthDate)
        guard monthIndex != NSNotFound,
            let dayIndex = self.daysForMonthAtIndex(monthIndex)?.indexOfObject(date.dayDate)
            where dayIndex != NSNotFound
            else { return nil }

        return NSIndexPath(forItem: dayIndex, inSection: monthIndex)
    }

    func indexPathUpdatesForEvent(newEventInfo: EventWithChangeInfo,
                                  oldEventInfo: EventWithChangeInfo) -> SelectiveUpdatingInfo
    {
        var paths = (deletions: [NSIndexPath](), insertions: [NSIndexPath](), reloads: [NSIndexPath](),
                     sectionDeletions: NSIndexSet(), sectionInsertions: NSIndexSet())

        func deleteOrReloadOldIndexPath(indexPath: NSIndexPath, forOldEvent event: Event) {
            // Update source cell given positions based on old events state.
            if self.indexPathForDayOfDate(event.startDate.dayDate) == nil { // Was only event for source cell.
                paths.deletions.append(indexPath)
                // Then delete month if also last cell in month section.
                if !self.months.containsObject(event.startDate.monthDate) {
                    paths.sectionDeletions = NSIndexSet(index: indexPath.section)
                }
            } else {
                paths.reloads.append(indexPath)
            }
        }

        let (oldEvent, oldIndexPath) = oldEventInfo
        let (newEvent, newIndexPath) = newEventInfo

        if // is a deletion:
            newIndexPath == nil && newEvent == nil,
            let oldIndexPath = oldIndexPath, oldEvent = oldEvent where !oldEvent.isNew
        {
            deleteOrReloadOldIndexPath(oldIndexPath, forOldEvent: oldEvent)
            return paths
        }

        let newDayDate = newEvent!.startDate.dayDate
        let newDayEvents = self.eventsForDayOfDate(newDayDate)
        let nextIndexPath = self.indexPathForDayOfDate(newDayDate)

        if // is a move:
            let nextIndexPath = nextIndexPath, oldIndexPath = oldIndexPath,
            let newEvent = newEvent, oldEvent = oldEvent
            where !oldEvent.isNew && oldEvent.startDate.dayDate != newDayDate
        {
            // Update source cell given positions based on old events state.
            deleteOrReloadOldIndexPath(oldIndexPath, forOldEvent: oldEvent)

            // Update destination cell given positions based on old events state.
            if newDayEvents?.count == 1 { // Is only event for destination cell.
                paths.insertions.append(nextIndexPath)
                if // first cell in new month section:
                    self.daysForMonthAtIndex(nextIndexPath.section)?.count == 1 &&
                    newEvent.startDate.monthDate != oldEvent.startDate.monthDate
                {
                    // Then insert month.
                    paths.sectionInsertions = NSIndexSet(index: nextIndexPath.section)
                }
            } else if let newIndexPath = newEventInfo.currentIndexPath {
                paths.reloads.append(newIndexPath)
            }

        } else if // is an addition:
            let nextIndexPath = nextIndexPath,
            let oldEvent = oldEvent where oldEvent.isNew
        {
            // Update destination cell.
            if newDayEvents?.count == 1 { // Is only event for destination cell.
                paths.insertions.append(nextIndexPath)
                // Then insert month if also first cell in month section.
                if self.daysForMonthAtIndex(nextIndexPath.section)?.count == 1 {
                    paths.sectionInsertions = NSIndexSet(index: nextIndexPath.section)
                }
            } else {
                paths.reloads.append(nextIndexPath)
            }
        }

        return paths
    }

}
