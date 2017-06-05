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

let today: Date = {
    var date = Date().dayDate
    let nextDate = date.dayDate(byAddingDays: 1)
    if Calendar.current.component(.day, from: nextDate) == 1 {
        date = nextDate
    }
    return date
}()
let tomorrow = today.dayDate(byAddingDays: 1) // Always same month.
let anotherMonth = today.dayDate(byAddingDays: 32)

final class TestEvent: Event {

    var testIdentifier: String!
    override var identifier: String { return testIdentifier ?? entity.eventIdentifier }

    init() {
        super.init(entity: EKEvent(eventStore: testStore))
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    convenience init(identifier: String?, startDate: Date) {
        self.init()

        self.testIdentifier = identifier
        self.startDate = startDate
    }

}
