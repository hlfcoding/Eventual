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

    /**
        To reduce boilerplate for UI tests, this wraps around `-expectationForPredicate:evaluatedWithObject`
        and `-waitForExpectationsWithTimeout:handler:`.
    
        - parameter timeout: Defaults to `5` seconds.
        - parameter then: Can be omitted so the expectation just fulfills without additional asserts.
          The element is passed in, though in most cases it shouldn't be needed.
    */
    func waitForElement(element: XCUIElement, timeout: NSTimeInterval?, then: ((XCUIElement) -> Void)?) {
        let predicate = NSPredicate(format: "exists == 1")
        expectationForPredicate(predicate, evaluatedWithObject: element) { () -> Bool in
            then?(element)
            return true
        }
        waitForExpectationsWithTimeout(timeout ?? 5.0, handler: nil)
    }

}
