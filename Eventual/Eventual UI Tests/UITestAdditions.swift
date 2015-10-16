//
//  UITestAdditions.swift
//  Eventual
//
//  Created by Peng Wang on 10/16/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {

    func waitForElement(element: XCUIElement, timeout: NSTimeInterval?, then: ((XCUIElement) -> Void)?) {
        let predicate = NSPredicate(format: "exists == 1")
        expectationForPredicate(predicate, evaluatedWithObject: element) { () -> Bool in
            then?(element)
            return true
        }
        waitForExpectationsWithTimeout(timeout ?? 5.0, handler: nil)
    }

}
