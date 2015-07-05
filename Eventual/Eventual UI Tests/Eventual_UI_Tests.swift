//
//  Eventual_UI_Tests.swift
//  Eventual UI Tests
//
//  Created by Peng Wang on 7/4/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import Foundation
import XCTest

class Eventual_UI_Tests: XCTestCase {

    var app: XCUIApplication! // Otherwise the app instance isn't exactly the same.

    override func setUp() {
        super.setUp()
        // Put setup code here.
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        self.app = XCUIApplication()
        self.app.launchArguments.append("-SynchronousData YES")
        self.app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here.
        super.tearDown()
    }
    
    func testNavigatingToExistingEvent() {
        let app = self.app
        // FIXME: This test fails because Xcode UI testing is half-baked, at least for collection view support.
        let firstCell = app.collectionViews[Label.MonthDays.rawValue].childrenMatchingType(.Cell).elementAtIndex(0)
        // Even the extension fails. :facepalm:
        firstCell.waitUntilExistsWithTimeout(2.0)
        firstCell.tap()
    }

}

extension XCUIElement {

    func waitUntilExistsWithTimeout(timeout: NSTimeInterval) {
        let startTime = NSDate.timeIntervalSinceReferenceDate()
        while !self.exists {
            guard (NSDate.timeIntervalSinceReferenceDate() - startTime) <= timeout else {
                XCTFail("Timed out waiting for element to exist.")
                return
            }
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, 0)
        }
    }

}