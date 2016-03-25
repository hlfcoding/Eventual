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

let today = NSDate().dayDate
let tomorrow = NSDate().dayDateFromAddingDays(1)
let anotherMonth = NSDate().dayDateFromAddingDays(100)

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
