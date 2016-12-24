//
//  UITestAdditions.swift
//  Eventual UI Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {

    var app: XCUIApplication { return XCUIApplication() }

    var firstDayCell: XCUIElement {
        let cellIdentifier = String.localizedStringWithFormat(a(.formatDayCell), 1, 1)
        return app.cells[cellIdentifier]
    }

    var firstEventCell: XCUIElement { return app.cells[a(.formatEventCell, 1)] }

    func navigationBackButton(_ identifier: Label) -> XCUIElement {
        return app.navigationBars[a(identifier)].buttons[a(.navigationBack)]
    }

    func setUpUITest() {
        // Auto-generated.
        XCUIDevice.shared().orientation = .portrait
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it
        // happens for each test method.
        app.launch()
    }

    func tapBackground(of collectionView: XCUIElement) {
        app.collectionViews[a(.dayEvents)].otherElements[a(.tappableBackground)].tap()
    }

    func toDayScreenFromMonthsScreen() {
        waitForMonthsScreen()
        // NOTE: This requires an editable event.
        firstDayCell.tap()
        waitForDayScreen()
    }

    func toEventScreenFromMonthsScreen() {
        toDayScreenFromMonthsScreen()
        // NOTE: This requires an editable event.
        firstEventCell.tap()
        waitForEventScreen()
    }

    func waitForDayScreen() {
        wait(for: app.collectionViews[a(.dayEvents)])
        wait(for: firstEventCell)
    }

    func waitForEventScreen() {
        wait(for: app.navigationBars[a(.eventScreenTitle)])
    }

    func waitForMonthsScreen() {
        wait(for: app.collectionViews[a(.monthDays)])
        wait(for: firstDayCell)
    }

    /**
     To reduce boilerplate for UI tests, this wraps around `-expectationForPredicate:evaluatedWithObject`
     and `-waitForExpectationsWithTimeout:handler:`.
    */
    func wait(for element: XCUIElement) {
        expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }

}
