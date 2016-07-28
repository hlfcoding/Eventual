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
        let cellIdentifier = NSString.localizedStringWithFormat(a(.FormatDayCell), 0, 0) as String
        return app.cells[cellIdentifier]
    }

    var firstEventCell: XCUIElement { return app.cells[a(.FormatEventCell, 0)] }

    func setUpUITest() {
        // Auto-generated.
        XCUIDevice.sharedDevice().orientation = .Portrait
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it
        // happens for each test method.
        app.launch()
    }
    
    func tapBackgroundOfCollectionView(collectionView: XCUIElement) {
        app.collectionViews[a(.DayEvents)].otherElements[a(.TappableBackground)].tap()
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
        waitForElement(app.collectionViews[a(.DayEvents)])
        waitForElement(firstEventCell)
    }

    func waitForEventScreen() {
        waitForElement(app.navigationBars[a(.EventScreenTitle)])
    }

    func waitForMonthsScreen() {
        waitForElement(app.collectionViews[a(.MonthDays)])
        waitForElement(firstDayCell)
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
