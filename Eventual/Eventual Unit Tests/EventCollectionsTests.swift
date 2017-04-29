//
//  EventCollectionsTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class EventCollectionsTests: XCTestCase {

    lazy var tomorrowEvents: [TestEvent] = [
        TestEvent(identifier: "Tomorrow-0", startDate: tomorrow),
        TestEvent(identifier: "Tomorrow-1", startDate: tomorrow),
    ]
    lazy var anotherMonthEvents: [TestEvent] = [
        TestEvent(identifier: "Another-Month-0", startDate: anotherMonth),
        TestEvent(identifier: "Another-Month-1", startDate: anotherMonth),
    ]
    lazy var events: [TestEvent] = self.tomorrowEvents + self.anotherMonthEvents

    override func setUp() {
        super.setUp()
    }

    func testArrangingEventsByMonthsAndDays() {
        let monthsEvents = MonthsEvents(events: events)
        var monthEvents: MonthEvents?
        XCTAssertEqual(monthsEvents.months.count, 2, "Months should be separated and populated correctly.")
        XCTAssertEqual(monthsEvents.months.count, monthsEvents.events.count, "Month start-dates should correspond to event collections.")

        monthEvents = monthsEvents.events[0] as? MonthEvents
        XCTAssertEqual(monthEvents?.days.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(monthEvents?.events.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(monthEvents?.days[0] as? Date, tomorrow, "Day start-date should be correct.")
        XCTAssertEqual((monthEvents?.events[0] as? DayEvents)?.count, tomorrowEvents.count, "Events should be grouped by day correctly.")

        monthEvents = monthsEvents.events[1] as? MonthEvents
        XCTAssertEqual(monthEvents?.days.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(monthEvents?.events.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(monthEvents?.days[0] as? Date, anotherMonth, "Day start-date should be correct.")
        XCTAssertEqual((monthEvents?.events[0] as? DayEvents)?.count, anotherMonthEvents.count, "Events should be grouped by day correctly.")
    }

    func testGettingEventsForMonthOfDate() {
        let monthsEvents = MonthsEvents(events: events)
        let currentMonthEvents = monthsEvents.eventsForMonth(of: tomorrow.monthDate)
        XCTAssertEqual(currentMonthEvents?.events.count, 1, "Finds and returns correct month's events.")
        let tomorrowEvents = (currentMonthEvents?.events[0] as? DayEvents)?.events as? [TestEvent]
        XCTAssertNotNil(tomorrowEvents)
        XCTAssertEqual(tomorrowEvents!, self.tomorrowEvents, "Finds and returns correct month's events.")
    }

    func testGettingEventsForDayOfDate() {
        let monthsEvents = MonthsEvents(events: events)
        let tomorrowEvents = monthsEvents.eventsForDay(of: tomorrow) as? [TestEvent]
        let anotherMonthEvents = monthsEvents.eventsForDay(of: anotherMonth) as? [TestEvent]
        XCTAssertNotNil(tomorrowEvents)
        XCTAssertEqual(tomorrowEvents!, self.tomorrowEvents, "Finds and returns correct day's events.")
        XCTAssertNotNil(anotherMonthEvents)
        XCTAssertEqual(anotherMonthEvents!, self.anotherMonthEvents, "Finds and returns correct day's events.")
    }

    func testGettingMonthAtIndex() {
        let monthsEvents = MonthsEvents(events: [])
        XCTAssertNil(monthsEvents.month(at: 0), "Returns nil if index out of bounds.")
    }

    // MARK: - NSIndexPath

    func testGettingEventsForDayAtIndexPath() {
        let monthsEvents = MonthsEvents(events: events)
        var anotherMonthEvents = monthsEvents.eventsForDay(at: IndexPath(item: 0, section: 1)) as? [TestEvent]
        XCTAssertNotNil(anotherMonthEvents)
        XCTAssertEqual(anotherMonthEvents!, self.anotherMonthEvents, "Finds and returns correct day's events.")

        anotherMonthEvents = monthsEvents.eventsForDay(at: IndexPath(item: 0, section: 2)) as? [TestEvent]
        XCTAssertNil(anotherMonthEvents, "Returns nil if index out of bounds.")
    }

    func testGettingDayDatesForIndexPath() {
        let monthsEvents = MonthsEvents(events: events)
        var anotherMonthDays = monthsEvents.daysForMonth(at: 1)
        var anotherMonthDay = monthsEvents.day(at: IndexPath(item: 0, section: 1))
        XCTAssertEqual(anotherMonthDays, [anotherMonth], "Finds and returns correct days.")
        XCTAssertEqual(anotherMonthDay, anotherMonth, "Finds and returns correct day.")

        anotherMonthDays = monthsEvents.daysForMonth(at: 2)
        anotherMonthDay = monthsEvents.day(at: IndexPath(item: 1, section: 1))
        XCTAssertNil(anotherMonthDays, "Returns nil if index out of bounds.")
        XCTAssertNil(anotherMonthDay, "Returns nil if index out of bounds.")
    }

    func testGettingIndexPathOfDayForDate() {
        let monthsEvents = MonthsEvents(events: events)
        let anotherMonthIndexPath = monthsEvents.indexPathForDay(of: anotherMonth)
        XCTAssertEqual(anotherMonthIndexPath, IndexPath(item: 0, section: 1), "Finds day and returns its index path.")

        let todayIndexPath = monthsEvents.indexPathForDay(of: Date())
        XCTAssertNil(todayIndexPath, "Returns nil if indices are out of bounds")
    }

    // MARK: indexPathUpdatesForEvent

    func eventWithChangeInfo(_ identifier: String?, _ startDate: Date?,
                             _ editEvent: ((Event) -> Void)? = nil) -> EventWithChangeInfo {
        guard let identifier = identifier, let startDate = startDate else {
            return EventWithChangeInfo(event: nil, indexPath: nil)
        }
        let event = TestEvent(identifier: identifier, startDate: startDate)
        event.isNew = false
        editEvent?(event)
        let info: EventWithChangeInfo = (
            event: event,
            indexPath: {
                guard !event.isNew else { return nil }
                switch startDate {
                case today: return IndexPath(item: 0, section: 0)
                case tomorrow: return IndexPath(item: 1, section: 0)
                case anotherMonth: return IndexPath(item: 0, section: 1)
                default: fatalError()
                }
            }()
        )
        return info
    }

    func testAddingEventToNewDay() {
        let new = eventWithChangeInfo("E-Added", tomorrow)
        let old = eventWithChangeInfo("E-Added", tomorrow) { $0.isNew = true }
        let otherEvent = TestEvent(identifier: "E-Existing", startDate: today)
        let monthsEvents = MonthsEvents(events: [otherEvent, new.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertEqual(paths.insertions, [new.indexPath!], "Inserts tomorrow at index path.")
        XCTAssertTrue(paths.sectionInsertions.count == 0, "Does not insert any month, due to no change.")
        XCTAssertTrue(paths.deletions.isEmpty, "Does not delete today, due to other event.")
        XCTAssertTrue(paths.sectionDeletions.count == 0, "Does not delete any month, due to no change.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload today, due to no total events change.")
    }

    func testAddingEventToDay() {
        let new = eventWithChangeInfo("E-Added", today)
        let old = eventWithChangeInfo("E-Added", today) { $0.isNew = true }
        let otherEvent = TestEvent(identifier: "E-Existing", startDate: today)
        let monthsEvents = MonthsEvents(events: [otherEvent, new.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertTrue(paths.insertions.isEmpty, "Does not insert today, due to other event.")
        XCTAssertTrue(paths.sectionInsertions.count == 0, "Does not insert any month, due to no change.")
        XCTAssertTrue(paths.deletions.isEmpty, "Does not delete today, due to addition.")
        XCTAssertTrue(paths.sectionDeletions.count == 0, "Does not delete any month, due to no change.")
        XCTAssertEqual(paths.reloads, [new.indexPath!], "Reloads today, due to total events change.")
    }

    func testAddingEventToNewMonth() {
        let new = eventWithChangeInfo("E-Added", today)
        let old = eventWithChangeInfo("E-Added", today) { $0.isNew = true }
        let otherEvent = TestEvent(identifier: "E-Existing", startDate: anotherMonth)
        let monthsEvents = MonthsEvents(events: [new.event!, otherEvent])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertEqual(paths.insertions, [new.indexPath!], "Inserts today's month at index path.")
        XCTAssertEqual(paths.sectionInsertions, IndexSet(integer: new.indexPath!.section))
        XCTAssertTrue(paths.deletions.isEmpty && paths.sectionDeletions.count == 0,
                      "Does not delete another month, due to other event.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload another month, due to no total events change.")
    }

    func testDeletingEventOfMonth() {
        let new = eventWithChangeInfo(nil, nil)
        let old = eventWithChangeInfo("E-Existing", today)
        let monthsEvents = MonthsEvents(events: [])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertTrue(paths.insertions.isEmpty && paths.sectionInsertions.count == 0, "Does not insert any day or month.")
        XCTAssertEqual(paths.deletions, [old.indexPath!], "Deletes day at index path.")
        XCTAssertEqual(paths.sectionDeletions, IndexSet(integer: old.indexPath!.section), "Deletes month at index path.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload any day.")
    }

    func testDeletingOneOfEventsOfDay() {
        let new = eventWithChangeInfo(nil, nil)
        let old = eventWithChangeInfo("E-Existing-0", today)
        let otherEvent = TestEvent(identifier: "E-Existing-1", startDate: today)
        let monthsEvents = MonthsEvents(events: [otherEvent])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertTrue(paths.insertions.isEmpty && paths.sectionInsertions.count == 0, "Does not insert any day or month.")
        XCTAssertTrue(paths.deletions.isEmpty && paths.sectionDeletions.count == 0,
                      "Does not delete day or month, due to other event.")
        XCTAssertEqual(paths.reloads, [old.indexPath!], "Reloads day, due to total events change.")
    }

    func testDeletingOneOfEventsOfMonth() {
        let new = eventWithChangeInfo(nil, nil)
        let old = eventWithChangeInfo("E-Existing-0", today)
        let otherEvent = TestEvent(identifier: "E-Existing-1", startDate: tomorrow)
        let monthsEvents = MonthsEvents(events: [otherEvent])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertTrue(paths.insertions.isEmpty && paths.sectionInsertions.count == 0, "Does not insert any day or month.")
        XCTAssertEqual(paths.deletions, [old.indexPath!], "Deletes today at index path.")
        XCTAssertTrue(paths.sectionDeletions.count == 0, "Does not delete month, due to other event.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload tomorrow, due to no total events change.")
    }

    func testEditingEventOfDay() {
        let new = eventWithChangeInfo("E-Edited", today) { $0.title.append("change") }
        let old = eventWithChangeInfo("E-Edited", today)
        let monthsEvents = MonthsEvents(events: [new.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertTrue(paths.insertions.isEmpty && paths.sectionInsertions.count == 0,
                      "Does not insert any day or month, due to no date change.")
        XCTAssertTrue(paths.deletions.isEmpty && paths.sectionDeletions.count == 0,
                      "Does not delete today or month, due to no date change.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload today, due to no date change.")
    }

    func testMovingOneOfEventsOfDayToDay() {
        let new = eventWithChangeInfo("E-Moved", tomorrow)
        let old = eventWithChangeInfo("E-Moved", today)
        let otherEvents = [TestEvent(identifier: "E-Existing-0", startDate: today),
                           TestEvent(identifier: "E-Existing-1", startDate: tomorrow)]
        let monthsEvents = MonthsEvents(events: otherEvents + [new.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertTrue(paths.insertions.isEmpty, "Does not insert any day, due to days having other events.")
        XCTAssertTrue(paths.sectionInsertions.count == 0, "Does not insert any month, due to no change.")
        XCTAssertTrue(paths.deletions.isEmpty, "Does not delete any day, due to days having other events.")
        XCTAssertTrue(paths.sectionDeletions.count == 0, "Does not delete any month, due to no change.")
        XCTAssertEqual(paths.reloads, [old.indexPath!, new.indexPath!], "Reloads days, due to total events changes.")
    }

    func testMovingOneOfEventsOfDayToNewDay() {
        let state = eventWithChangeInfo("E-Moved", tomorrow)
        let new = eventWithChangeInfo("E-Moved", today)
        let otherEvent = TestEvent(identifier: "E-Existing", startDate: today)
        let monthsEvents = MonthsEvents(events: [otherEvent, state.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: state, oldInfo: new)
        XCTAssertEqual(paths.insertions, [state.indexPath!], "Inserts tomorrow at index path.")
        XCTAssertTrue(paths.sectionInsertions.count == 0, "Does not insert any month, due to no change.")
        XCTAssertTrue(paths.deletions.isEmpty, "Does not delete today, due to other event.")
        XCTAssertTrue(paths.sectionDeletions.count == 0, "Does not delete any month, due to no change.")
        XCTAssertEqual(paths.reloads, [new.indexPath!], "Reloads today, due to total events change.")
    }

    func testMovingEventOfDayToDay() {
        let new = eventWithChangeInfo("E-Moved", tomorrow)
        let old = eventWithChangeInfo("E-Moved", today)
        let otherEvent = TestEvent(identifier: "E-Existing", startDate: tomorrow)
        let monthsEvents = MonthsEvents(events: [otherEvent, new.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertTrue(paths.insertions.isEmpty, "Does not insert tomorrow, due to other event.")
        XCTAssertTrue(paths.sectionInsertions.count == 0, "Does not insert any month, due to no change.")
        XCTAssertEqual(paths.deletions, [old.indexPath!], "Deletes today at index path.")
        XCTAssertTrue(paths.sectionDeletions.count == 0, "Does not delete any month, due to no change.")
        XCTAssertEqual(paths.reloads, [new.indexPath!], "Reloads tomorrow, due to total events change.")
    }

    func testMovingEventOfDayToNewDay() {
        let new = eventWithChangeInfo("E-Moved", tomorrow)
        let old = eventWithChangeInfo("E-Moved", today)
        let monthsEvents = MonthsEvents(events: [new.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertEqual(paths.insertions, [old.indexPath!], "Inserts tomorrow at index path, accounting deletion.")
        XCTAssertTrue(paths.sectionInsertions.count == 0, "Does not insert any month, due to no change.")
        XCTAssertEqual(paths.deletions, [old.indexPath!], "Deletes today at index path.")
        XCTAssertTrue(paths.sectionDeletions.count == 0, "Does not delete any month, due to no change.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload, only insertion and deletion.")
    }

    func testMovingEventToNewMonth() {
        let new = eventWithChangeInfo("E-Moved", today)
        let old = eventWithChangeInfo("E-Moved", anotherMonth)
        let monthsEvents = MonthsEvents(events: [new.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(newInfo: new, oldInfo: old)
        XCTAssertEqual(paths.insertions, [new.indexPath!], "Inserts today at index path.")
        XCTAssertEqual(paths.sectionInsertions, IndexSet(integer: new.indexPath!.section))
        XCTAssertEqual(paths.deletions, [old.indexPath!], "Deletes another month at index path.")
        XCTAssertEqual(paths.sectionDeletions, IndexSet(integer: old.indexPath!.section))
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload, only insertion and deletion.")
    }

}
