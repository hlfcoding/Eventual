//
//  EventCollections.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import EventKit

typealias DayEvents = NSArray

let RecurringDate = Date.distantFuture.dayDate

class EventsByDate {

    let dates: NSMutableArray = []
    let events: NSMutableArray = []

    fileprivate func addDateIfNeeded(_ date: Date) -> Date {
        guard dates.index(of: date) != NSNotFound else {
            dates.add(date)
            return date
        }
        return date
    }

    fileprivate func events(forDate date: Date) -> Any? {
        let index = dates.index(of: date)
        guard index != NSNotFound && events.count > index else { return nil }
        return events[index] as Any?
    }

}

final class MonthEvents: EventsByDate {

    var days: NSMutableArray { return dates }

    var lastDay: Date? {
        let day = days.lastObject as? Date
        return day
    }

    var recurringIndex: Int? {
        let index = dates.index(of: RecurringDate)
        guard index != NSNotFound else { return nil }
        return index
    }

    fileprivate override func addDateIfNeeded(_ date: Date) -> Date {
        if let recurringIndex = recurringIndex {
            guard dates.index(of: date) == NSNotFound else { return date }
            dates.insert(date, at: recurringIndex)
            events.insert(NSMutableArray(), at: recurringIndex)
            return date
        }
        return super.addDateIfNeeded(date)
    }

    fileprivate func day(forEvent event: Event) -> Date {
        if event.entity.hasRecurrenceRules {
            return addDateIfNeeded(RecurringDate)
        }
        return addDateIfNeeded(event.startDate.dayDate)
    }

    fileprivate func events(forDay day: Date) -> NSMutableArray {
        guard let dayEvents = events(forDate: day) as? NSMutableArray else {
            let dayEvents = NSMutableArray()
            events.add(dayEvents)
            return dayEvents
        }
        return dayEvents
    }

    /** Takes user-provided `date`, not guaranteed valid. */
    func eventsForDay(of date: Date) -> DayEvents? {
        return events(forDate: date.dayDate) as? NSMutableArray
    }

}

final class MonthsEvents: EventsByDate {

    var months: NSMutableArray { return dates }

    init(events: [Event]) {
        super.init()

        for event in events {
            let month = self.month(forEvent: event)
            let monthEvents = self.events(forMonth: month)
            let day = monthEvents.day(forEvent: event)
            let dayEvents = monthEvents.events(forDay: day)
            // This is why Swift arrays (assign by value) won't work.
            dayEvents.add(event)
        }
    }

    fileprivate func month(forEvent event: Event) -> Date {
        return addDateIfNeeded(event.startDate.monthDate)
    }

    fileprivate func events(forMonth month: Date) -> MonthEvents {
        var monthEvents = events(forDate: month)
        if monthEvents == nil {
            monthEvents = MonthEvents()
            events.add(monthEvents!)
        }
        return monthEvents as! MonthEvents
    }

    func month(at index: Int) -> Date? {
        guard months.count > 0 else { return nil }
        return months[index] as? Date
    }

    /** Takes user-provided `date`, not guaranteed valid. */
    func eventsForMonth(of date: Date) -> MonthEvents? {
        return events(forDate: date.monthDate) as? MonthEvents
    }

    /** Takes user-provided `date`, not guaranteed valid. */
    func eventsForDay(of date: Date) -> DayEvents? {
        return eventsForMonth(of: date)?.eventsForDay(of: date)
    }

}

// MARK: IndexPath

typealias EventWithChangeInfo = (event: Event?, indexPath: IndexPath?)
typealias SelectiveUpdatingInfo = (
    deletions: [IndexPath], insertions: [IndexPath], reloads: [IndexPath],
    sectionDeletions: IndexSet, sectionInsertions: IndexSet
)

extension MonthsEvents {

    fileprivate func eventsForMonth(at indexPath: IndexPath) -> MonthEvents? {
        guard events.count > indexPath.section else { return nil }
        return events[indexPath.section] as? MonthEvents
    }

    func daysForMonth(at index: Int) -> NSArray? {
        return eventsForMonth(at: index)?.days
    }

    func eventsForMonth(at index: Int) -> MonthEvents? {
        guard months.count > index else { return nil }
        return events[index] as? MonthEvents
    }

    func eventsForDay(at indexPath: IndexPath) -> DayEvents? {
        let monthEvents = eventsForMonth(at: indexPath)
        guard let count = monthEvents?.events.count, count > indexPath.item else { return nil }
        return monthEvents?.events[indexPath.item] as? DayEvents
    }

    func day(at indexPath: IndexPath) -> Date? {
        guard let days = eventsForMonth(at: indexPath)?.days, days.count > indexPath.item
            else { return nil }
        return days[indexPath.item] as? Date
    }

    func indexPathForDay(of date: Date) -> IndexPath? {
        let monthIndex = months.index(of: date.monthDate)
        guard monthIndex != NSNotFound,
            let dayIndex = daysForMonth(at: monthIndex)?.index(of: date.dayDate),
            dayIndex != NSNotFound
            else { return nil }

        return IndexPath(item: dayIndex, section: monthIndex)
    }

    func indexPathUpdatesForEvent(newInfo: EventWithChangeInfo,
                                  oldInfo: EventWithChangeInfo) -> SelectiveUpdatingInfo {
        var paths = (deletions: [IndexPath](), insertions: [IndexPath](), reloads: [IndexPath](),
                     sectionDeletions: IndexSet(), sectionInsertions: IndexSet())

        func deleteOrReload(_ oldIndexPath: IndexPath, _ oldEvent: Event) {
            // Update source cell given positions based on old events state.
            if indexPathForDay(of: oldEvent.startDate.dayDate) == nil { // Was only event for source cell.
                paths.deletions.append(oldIndexPath)
                // Then delete month if also last cell in month section.
                if !months.contains(oldEvent.startDate.monthDate) {
                    paths.sectionDeletions = IndexSet(integer: oldIndexPath.section)
                }
            } else {
                paths.reloads.append(oldIndexPath)
            }
        }

        let (oldEvent, oldIndexPath) = oldInfo
        let (newEvent, newIndexPath) = newInfo

        if newIndexPath == nil && newEvent == nil, let oldIndexPath = oldIndexPath,
            let oldEvent = oldEvent, !oldEvent.isNew {
            // Is a deletion:
            deleteOrReload(oldIndexPath, oldEvent)
            return paths
        }

        let newDayDate = newEvent!.startDate.dayDate
        let newDayEvents = eventsForDay(of: newDayDate)
        let nextIndexPath = indexPathForDay(of: newDayDate)

        if let nextIndexPath = nextIndexPath, let oldIndexPath = oldIndexPath, let newEvent = newEvent,
            let oldEvent = oldEvent, !oldEvent.isNew && oldEvent.startDate.dayDate != newDayDate {
            // Is a move:
            // Update source cell given positions based on old events state.
            deleteOrReload(oldIndexPath, oldEvent)

            // Update destination cell given positions based on old events state.
            if newDayEvents?.count == 1 { // Is only event for destination cell.
                paths.insertions.append(nextIndexPath)
                if
                    daysForMonth(at: nextIndexPath.section)?.count == 1 &&
                    newEvent.startDate.monthDate != oldEvent.startDate.monthDate {
                    // First cell in new month section:
                    // Then insert month.
                    paths.sectionInsertions = IndexSet(integer: nextIndexPath.section)
                }
            } else if let newIndexPath = newInfo.indexPath {
                paths.reloads.append(newIndexPath)
            }

        } else if let nextIndexPath = nextIndexPath, let oldEvent = oldEvent, oldEvent.isNew {
            // Is an addition:
            // Update destination cell.
            if newDayEvents?.count == 1 { // Is only event for destination cell.
                paths.insertions.append(nextIndexPath)
                // Then insert month if also first cell in month section.
                if daysForMonth(at: nextIndexPath.section)?.count == 1 {
                    paths.sectionInsertions = IndexSet(integer: nextIndexPath.section)
                }
            } else {
                paths.reloads.append(nextIndexPath)
            }
        }

        return paths
    }

}
