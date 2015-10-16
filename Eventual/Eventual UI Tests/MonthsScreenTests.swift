//
//  MonthsScreenTests.swift
//  Eventual UI Tests
//
//  Created by Peng Wang on 7/4/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import Foundation
import XCTest

class MonthsScreenTests: XCTestCase {

    var app: XCUIApplication { return XCUIApplication() }

    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testMonthsCollectionViewExistence() {
        XCTAssert(app.collectionViews["Eventful Days By Month"].exists)
    }

    func testNavigatingToFirstDay() {
        let app = self.app
        waitForElement(app.cells["Day Cell At Section 0 Item 0"], timeout: nil) { (firstCell) in
            firstCell.tap()
            XCTAssert(app.collectionViews["Day Events"].exists)
        }
    }

}
