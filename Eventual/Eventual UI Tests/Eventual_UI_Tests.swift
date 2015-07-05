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

    override func setUp() {
        super.setUp()
        // Put setup code here.
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        // Put teardown code here.
        super.tearDown()
    }
    
}
