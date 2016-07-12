//
//  UITestAdditions.swift
//  Eventual UI Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {

    func firstDayCellIdentifier() -> String {
        return NSString.localizedStringWithFormat(a(.FormatDayCell), 0, 0) as String
    }

    /**
     To reduce boilerplate for UI tests, this wraps around `-expectationForPredicate:evaluatedWithObject`
     and `-waitForExpectationsWithTimeout:handler:`.
    */
    func waitForElement(element: XCUIElement) {
        expectationForPredicate(NSPredicate(format: "exists == true"), evaluatedWithObject: element, handler: nil)
        waitForExpectationsWithTimeout(5, handler: nil)
    }

}
