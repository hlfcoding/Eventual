//
//  Stubs.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import Foundation
import EventKit
@testable import Eventual

let testStore = EKEventStore()

let today: NSDate = {
    var date = NSDate().dayDate
    let nextDate = date.dayDateFromAddingDays(1)
    if NSCalendar.currentCalendar().component(.Day, fromDate: nextDate) == 1 { date = nextDate }
    return date
}()
let tomorrow = today.dayDateFromAddingDays(1) // Always same month.
let anotherMonth = today.dayDateFromAddingDays(32)

class TestEvent: Event {

    var testIdentifier: String!
    override var identifier: String { return testIdentifier ?? self.entity.eventIdentifier }

    init() {
        super.init(entity: EKEvent(eventStore: testStore))
    }

    convenience init(identifier: String?, startDate: NSDate) {
        self.init()

        self.testIdentifier = identifier
        self.startDate = startDate
    }

}
