//
//  Stubs.swift
//  Eventual
//
//  Created by Peng Wang on 2/16/16.
//  Copyright (c) 2016 Eventual App. All rights reserved.
//

import Foundation
import EventKit
@testable import Eventual

let testStore = EKEventStore()

class TestEvent: Event {

    var testIdentifier: String!
    override var identifier: String { return testIdentifier ?? self.entity.eventIdentifier }

    init() {
        super.init(entity: EKEvent(eventStore: testStore))
    }

    convenience init(identifier: String, startDate: NSDate) {
        self.init()

        self.testIdentifier = identifier
        self.startDate = startDate
    }

}
