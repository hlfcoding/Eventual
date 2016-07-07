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
        TestEvent(identifier: "Tomorrow-1", startDate: tomorrow)
    ]
    lazy var anotherMonthEvents: [TestEvent] = [
        TestEvent(identifier: "Another-Month-0", startDate: anotherMonth),
        TestEvent(identifier: "Another-Month-1", startDate: anotherMonth)
    ]
    lazy var events: [TestEvent] = self.tomorrowEvents + self.anotherMonthEvents

    override func setUp() {
        super.setUp()
    }

    func testArrangingEventsByMonthsAndDays() {
        let monthsEvents = MonthsEvents(events: self.events)
        var monthEvents: MonthEvents?
        XCTAssertEqual(monthsEvents.months.count, 2, "Months should be separated and populated correctly.")
        XCTAssertEqual(monthsEvents.months.count, monthsEvents.events.count, "Month start-dates should correspond to event collections.")

        monthEvents = monthsEvents.events[0] as? MonthEvents
        XCTAssertEqual(monthEvents?.days.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(monthEvents?.events.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(monthEvents?.days[0] as? NSDate, tomorrow, "Day start-date should be correct.")
        XCTAssertEqual((monthEvents?.events[0] as? [TestEvent])?.count, self.tomorrowEvents.count, "Events should be grouped by day correctly.")

        monthEvents = monthsEvents.events[1] as? MonthEvents
        XCTAssertEqual(monthEvents?.days.count, 1, "Days should be separated and populated correctly.")
        XCTAssertEqual(monthEvents?.events.count, 1, "Month start dates should correspond to event collections.")
        XCTAssertEqual(monthEvents?.days[0] as? NSDate, anotherMonth, "Day start-date should be correct.")
        XCTAssertEqual((monthEvents?.events[0] as? [TestEvent])?.count, self.anotherMonthEvents.count, "Events should be grouped by day correctly.")
    }

    func testGettingEventsForMonthOfDate() {
        let monthsEvents = MonthsEvents(events: self.events)
        let currentMonthEvents = monthsEvents.eventsForMonthOfDate(tomorrow.monthDate)
        XCTAssertEqual(currentMonthEvents?.events.count, 1, "Finds and returns correct month's events.")
        XCTAssertEqual(currentMonthEvents?.events[0] as? DayEvents, self.tomorrowEvents, "Finds and returns correct month's events.")
    }

    func testGettingEventsForDayOfDate() {
        let monthsEvents = MonthsEvents(events: self.events)
        let tomorrowEvents = monthsEvents.eventsForDayOfDate(tomorrow)
        let anotherMonthEvents = monthsEvents.eventsForDayOfDate(anotherMonth)
        XCTAssertEqual(tomorrowEvents, self.tomorrowEvents, "Finds and returns correct day's events.")
        XCTAssertEqual(anotherMonthEvents, self.anotherMonthEvents, "Finds and returns correct day's events.")
    }

    func testGettingMonthAtIndex() {
        let monthsEvents = MonthsEvents(events: [])
        XCTAssertNil(monthsEvents.monthAtIndex(0), "Returns nil if index out of bounds.")
    }

    // MARK: - NSIndexPath

    func testGettingEventsForDayAtIndexPath() {
        let monthsEvents = MonthsEvents(events: self.events)
        var anotherMonthEvents = monthsEvents.eventsForDayAtIndexPath(NSIndexPath(forItem: 0, inSection: 1))
        XCTAssertEqual(anotherMonthEvents, self.anotherMonthEvents, "Finds and returns correct day's events.")

        anotherMonthEvents = monthsEvents.eventsForDayAtIndexPath(NSIndexPath(forItem: 0, inSection: 2))
        XCTAssertNil(anotherMonthEvents, "Returns nil if index out of bounds.")
    }

    func testGettingDayDatesForIndexPath() {
        let monthsEvents = MonthsEvents(events: self.events)
        var anotherMonthDays = monthsEvents.daysForMonthAtIndex(1)
        var anotherMonthDay = monthsEvents.dayAtIndexPath(NSIndexPath(forItem: 0, inSection: 1))
        XCTAssertEqual(anotherMonthDays, [anotherMonth], "Finds and returns correct days.")
        XCTAssertEqual(anotherMonthDay, anotherMonth, "Finds and returns correct day.")

        anotherMonthDays = monthsEvents.daysForMonthAtIndex(2)
        anotherMonthDay = monthsEvents.dayAtIndexPath(NSIndexPath(forItem: 1, inSection: 1))
        XCTAssertNil(anotherMonthDays, "Returns nil if index out of bounds.")
        XCTAssertNil(anotherMonthDay, "Returns nil if index out of bounds.")
    }

    func testGettingIndexPathOfDayForDate() {
        let monthsEvents = MonthsEvents(events: self.events)
        let anotherMonthIndexPath = monthsEvents.indexPathForDayOfDate(anotherMonth)
        XCTAssertEqual(anotherMonthIndexPath, NSIndexPath(forItem: 0, inSection: 1), "Finds day and returns its index path.")

        let todayIndexPath = monthsEvents.indexPathForDayOfDate(NSDate())
        XCTAssertNil(todayIndexPath, "Returns nil if indices are out of bounds")
    }

    // MARK: indexPathUpdatesForEvent

    func eventWithChangeInfo(identifier: String, _ startDate: NSDate, _ editEvent: ((Event) -> Void)? = nil)
         -> EventWithChangeInfo
    {
        let event = TestEvent(identifier: identifier, startDate: startDate)
        event.isNew = false
        editEvent?(event)
        let info: EventWithChangeInfo = (
            event: event,
            currentIndexPath: {
                guard !event.isNew else { return nil }
                switch startDate {
                case today: return NSIndexPath(forItem: 0, inSection: 0)
                case tomorrow: return NSIndexPath(forItem: 1, inSection: 0)
                case anotherMonth: return NSIndexPath(forItem: 0, inSection: 1)
                default: fatalError()
                }
            }()
        )
        return info
    }

    func testAddingEventToNewDay() {
        let state = eventWithChangeInfo("E-Added", tomorrow)
        let oldState = eventWithChangeInfo("E-Added", tomorrow) { $0.isNew = true }
        let otherEvent = TestEvent(identifier: "E-Existing", startDate: today)
        let monthsEvents = MonthsEvents(events: [otherEvent, state.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(state, oldEventInfo: oldState)
        XCTAssertEqual(paths.insertions, [state.currentIndexPath!], "Inserts tomorrow at index path.")
        XCTAssertTrue(paths.deletions.isEmpty, "Does not delete today, due to other event.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload today, due to no total events change.")
    }

    func testAddingEventToDay() {
        let state = eventWithChangeInfo("E-Added", today)
        let oldState = eventWithChangeInfo("E-Added", today) { $0.isNew = true }
        let otherEvent = TestEvent(identifier: "E-Existing", startDate: today)
        let monthsEvents = MonthsEvents(events: [otherEvent, state.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(state, oldEventInfo: oldState)
        XCTAssertTrue(paths.insertions.isEmpty, "Does not insert today, due to other event.")
        XCTAssertTrue(paths.deletions.isEmpty, "Does not delete today, due to addition.")
        XCTAssertEqual(paths.reloads, [state.currentIndexPath!], "Reloads today, due to total events change.")
    }

    func testAddingEventToNewMonth() {
        let state = eventWithChangeInfo("E-Added", today)
        let oldState = eventWithChangeInfo("E-Added", today) { $0.isNew = true }
        let otherEvent = TestEvent(identifier: "E-Existing", startDate: anotherMonth)
        let monthsEvents = MonthsEvents(events: [state.event!, otherEvent])

        let paths = monthsEvents.indexPathUpdatesForEvent(state, oldEventInfo: oldState)
        XCTAssertEqual(paths.insertions, [state.currentIndexPath!], "Inserts today's month at index path.")
        XCTAssertTrue(paths.deletions.isEmpty, "Does not delete another month, due to other event.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload another month, due to no total events change.")
    }
    
    func testEditingEventOfDay() {
        let state = eventWithChangeInfo("E-Edited", today) { $0.title.appendContentsOf("change") }
        let oldState = eventWithChangeInfo("E-Edited", today)
        let monthsEvents = MonthsEvents(events: [state.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(state, oldEventInfo: oldState)
        XCTAssertTrue(paths.insertions.isEmpty, "Does not insert any day, due to no date change.")
        XCTAssertTrue(paths.deletions.isEmpty, "Does not delete today, due to no date change.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload today, due to no date change.")
    }

    func testMovingOneOfEventsOfDayToDay() {
        let state = eventWithChangeInfo("E-Moved", tomorrow)
        let oldState = eventWithChangeInfo("E-Moved", today)
        let otherEvents = [TestEvent(identifier: "E-Existing-0", startDate: today),
                           TestEvent(identifier: "E-Existing-1", startDate: tomorrow)]
        let monthsEvents = MonthsEvents(events: otherEvents + [state.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(state, oldEventInfo: oldState)
        XCTAssertTrue(paths.insertions.isEmpty, "Does not insert any day, due to days having other events.")
        XCTAssertTrue(paths.deletions.isEmpty, "Does not delete any day, due to days having other events.")
        XCTAssertEqual(paths.reloads, [oldState.currentIndexPath!, state.currentIndexPath!], "Reloads days, due to total events changes.")
    }

    func testMovingOneOfEventsOfDayToNewDay() {
        let state = eventWithChangeInfo("E-Moved", tomorrow)
        let oldState = eventWithChangeInfo("E-Moved", today)
        let otherEvent = TestEvent(identifier: "E-Existing", startDate: today)
        let monthsEvents = MonthsEvents(events: [otherEvent, state.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(state, oldEventInfo: oldState)
        XCTAssertEqual(paths.insertions, [state.currentIndexPath!], "Inserts tomorrow at index path.")
        XCTAssertTrue(paths.deletions.isEmpty, "Does not delete today, due to other event.")
        XCTAssertEqual(paths.reloads, [oldState.currentIndexPath!], "Reloads today, due to total events change.")
    }

    func testMovingEventOfDayToDay() {
        let state = eventWithChangeInfo("E-Moved", tomorrow)
        let oldState = eventWithChangeInfo("E-Moved", today)
        let otherEvent = TestEvent(identifier: "E-Existing", startDate: tomorrow)
        let monthsEvents = MonthsEvents(events: [otherEvent, state.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(state, oldEventInfo: oldState)
        XCTAssertTrue(paths.insertions.isEmpty, "Does not insert tomorrow, due to other event.")
        XCTAssertEqual(paths.deletions, [oldState.currentIndexPath!], "Deletes today at index path.")
        XCTAssertEqual(paths.reloads, [state.currentIndexPath!], "Reloads tomorrow, due to total events change.")
    }

    func testMovingEventOfDayToNewDay() {
        let state = eventWithChangeInfo("E-Moved", tomorrow)
        let oldState = eventWithChangeInfo("E-Moved", today)
        let monthsEvents = MonthsEvents(events: [state.event!])

        let paths = monthsEvents.indexPathUpdatesForEvent(state, oldEventInfo: oldState)
        XCTAssertEqual(paths.insertions, [oldState.currentIndexPath!], "Inserts tomorrow at index path, but accounting deletion.")
        XCTAssertEqual(paths.deletions, [oldState.currentIndexPath!], "Deletes today at index path.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload, only insertion and deletion.")
    }

    func testMovingEventToNewMonth() {
        let state = eventWithChangeInfo("E-Moved", today)
        let oldState = eventWithChangeInfo("E-Moved", anotherMonth)
        let monthsEvents = MonthsEvents(events: [state.event!])
        
        let paths = monthsEvents.indexPathUpdatesForEvent(state, oldEventInfo: oldState)
        XCTAssertEqual(paths.insertions, [state.currentIndexPath!], "Inserts today at index path.")
        XCTAssertEqual(paths.deletions, [oldState.currentIndexPath!], "Deletes another month at index path.")
        XCTAssertTrue(paths.reloads.isEmpty, "Does not reload, only insertion and deletion.")
    }
    
}
