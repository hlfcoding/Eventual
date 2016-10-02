//
//  IconBarButtonItemTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class IconBarButtonItemTests: XCTestCase {

    lazy var item = IconBarButtonItem()

    func testInitialState() {
        XCTAssertTrue(item.state == .normal)
    }

    func testToggleActiveState() {
        item.toggle(state: .active, on: true)
        XCTAssertTrue(item.state == .active, "Toggles on.")

        item.toggle(state: .filled, on: true)
        XCTAssertTrue(item.state == .active, "Fails toggling on for other non-normal states.")

        item.toggle(state: .active, on: false)
        XCTAssertTrue(item.state == .normal, "Toggles off.")
    }

    func testToggleFilledState() {
        item.toggle(state: .filled, on: true)
        XCTAssertTrue(item.state == .filled, "Toggles on.")

        item.toggle(state: .active, on: true)
        XCTAssertTrue(item.state == .filled, "Fails toggling on for other non-normal states.")

        item.toggle(state: .filled, on: false)
        XCTAssertTrue(item.state == .normal, "Toggles off.")
    }

    func testToggleSuccessfulState() {
        item.toggle(state: .successful, on: true)
        XCTAssertTrue(item.state == .successful, "Toggles on.")

        item.toggle(state: .successful, on: false)
        XCTAssertTrue(item.state == .normal, "Toggles off.")
    }

}
