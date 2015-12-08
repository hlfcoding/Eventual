//
//  DayScreenTests.swift
//  Eventual
//
//  Created by Peng Wang on 10/18/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import XCTest

class DayScreenTests: XCTestCase {

    var app: XCUIApplication { return XCUIApplication() }
    var collectionView: XCUIElement!
    var navigationBar: XCUIElement!

    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        self.continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        self.app.launch()
        self.collectionView = self.app.collectionViews[Label.DayEvents.rawValue]
        self.navigationBar = self.app.navigationBars.element
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func navigateToDayScreen(then: () -> Void) {
        let firstCell = self.app.cells[NSString(format: Label.FormatDayCell.rawValue, 0, 0) as String]
        self.waitForElement(firstCell, timeout: nil) { (_) in
            firstCell.tap()
            XCTAssert(self.collectionView.exists)
            then()
        }
    }

    func testNavigatingToFirstEvent() {
        self.navigateToDayScreen {
            self.app.cells[NSString(format: Label.FormatEventCell.rawValue, 0) as String].tap()
            XCTAssert(self.navigationBar.otherElements[Label.EventScreenTitle.rawValue].exists)
        }
    }

    func pending_testTapBackgroundToAddEvent() {
        self.navigateToDayScreen {
            let background = self.collectionView.otherElements[Label.TappableBackground.rawValue]
            self.waitForElement(background, timeout: nil) { (_) in
                background.tap()
                // Verify by manual observation.
                // TODO: Somehow nothing on Event screen can be found.
                // self.waitForElement(self.app.otherElements[Label.EventForm.rawValue])
            }
        }
    }

}
