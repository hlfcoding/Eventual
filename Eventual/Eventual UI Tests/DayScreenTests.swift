//
//  DayScreenTests.swift
//  Eventual UI Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest

final class DayScreenTests: XCTestCase {

    var app: XCUIApplication!
    var collectionView: XCUIElement!
    var navigationBar: XCUIElement!

    override func setUp() {
        super.setUp()
        // Auto-generated.
        XCUIDevice.sharedDevice().orientation = .Portrait
        // In UI tests it is usually best to stop immediately when a failure occurs.
        self.continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it
        // happens for each test method.
        self.app = XCUIApplication()
        self.app.launch()
        self.collectionView = self.app.collectionViews[a(.DayEvents)]
        self.navigationBar = self.app.navigationBars.element
    }

    func navigateToDayScreen(then: () -> Void) {
        let firstCell = self.app.cells[self.firstDayCellIdentifier()]
        self.waitForElement(firstCell, timeout: nil) { (_) in
            firstCell.tap()
            XCTAssert(self.collectionView.exists)
            then()
        }
    }

    func testNavigatingToFirstEvent() {
        self.navigateToDayScreen {
            self.app.cells[NSString(format: a(.FormatEventCell), 0) as String].tap()
            XCTAssert(self.navigationBar.otherElements[a(.EventScreenTitle)].exists)
        }
    }

    func pending_testTapBackgroundToAddEvent() {
        self.navigateToDayScreen {
            let background = self.collectionView.otherElements[a(.TappableBackground)]
            self.waitForElement(background, timeout: nil) { (_) in
                background.tap()
                // Verify by manual observation.
                // TODO: Somehow nothing on Event screen can be found.
                // self.waitForElement(self.app.otherElements[a(.EventForm)])
            }
        }
    }

}
