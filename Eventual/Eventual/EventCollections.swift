//
//  EventCollections.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import EventKit

let RecurringDate = Date.distantFuture.dayDate

final class DayEvents {

    var events: [Any] {
        return mutableEvents as NSArray as! [Any]
    }
    fileprivate let mutableEvents: NSMutableArray = []

    var count: Int {
        if let cachedCount = cachedCount {
            return cachedCount
        }
        var count = mutableEvents.count
        for case let instances as NSArray in mutableEvents {
            count += instances.count - 1
        }
        cachedCount = count
        return count
    }
    fileprivate var cachedCount: Int?

    static func event(at index: Int, of events: [Any]) -> Event? {
        guard events.count > index else { return nil }
        var event = events[index]
        if let instances = event as? NSArray {
            event = instances.firstObject!
        }
        return event as? Event
    }

    fileprivate func index(of event: Event) -> Int? {
        let index = mutableEvents.indexOfObject(passingTest:) { obj, idx, stop in
            let addedEvent: Event
            if let instances = obj as? NSArray {
                addedEvent = instances.firstObject as! Event
            } else {
                addedEvent = obj as! Event
            }
            return event.title == addedEvent.title
        }
        return index == NSNotFound ? nil : index
    }

    fileprivate func add(event: Event) {
        if event.entity.hasRecurrenceRules, let addedIndex = index(of: event) {
            add(instance: event, at: addedIndex)
            return
        }
        // This is why Swift arrays (assign by value) won't work.
        mutableEvents.add(event)
    }

    fileprivate func add(instance: Event, at index: Int) {
        guard let instances = mutableEvents[index] as? NSMutableArray else {
            mutableEvents[index] = NSMutableArray(objects: mutableEvents[index], instance)
            return
        }
        instances.add(instance)
    }

}

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
        var index = days.count - 1
        guard index >= 0 else { return nil }
        if days[index] as? Date == RecurringDate {
            guard days.count > 1 else { return nil }
            index -= 1
        }
        return days[index] as? Date
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
            events.insert(DayEvents(), at: recurringIndex)
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

    func events(forDay day: Date) -> DayEvents {
        guard let dayEvents = events(forDate: day) as? DayEvents else {
            let dayEvents = DayEvents()
            events.add(dayEvents)
            return dayEvents
        }
        return dayEvents
    }

    /** Takes user-provided `date`, not guaranteed valid. */
    func eventsForDay(of date: Date) -> [Any]? {
        return (events(forDate: date.dayDate) as? DayEvents)?.events
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
            dayEvents.add(event: event)
        }
    }

    fileprivate func month(forEvent event: Event) -> Date {
        return addDateIfNeeded(event.startDate.monthDate)
    }

    func events(forMonth month: Date) -> MonthEvents {
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
    func eventsForDay(of date: Date) -> [Any]? {
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

    func eventsForDay(at indexPath: IndexPath) -> [Any]? {
        let monthEvents = eventsForMonth(at: indexPath)
        guard let count = monthEvents?.events.count, count > indexPath.item else { return nil }
        return (monthEvents?.events[indexPath.item] as? DayEvents)?.events
    }

    func day(at indexPath: IndexPath) -> Date? {
        guard let days = eventsForMonth(at: indexPath)?.days, days.count > indexPath.item
            else { return nil }
        return days[indexPath.item] as? Date
    }

    func indexPathForDay(of date: Date, monthDate: Date? = nil) -> IndexPath? {
        let monthIndex = months.index(of: monthDate ?? date.monthDate)
        guard let days = daysForMonth(at: monthIndex) else { return nil }
        let dayIndex = days.index(of:(date == RecurringDate) ? date : date.dayDate)
        guard dayIndex != NSNotFound else { return nil }
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
