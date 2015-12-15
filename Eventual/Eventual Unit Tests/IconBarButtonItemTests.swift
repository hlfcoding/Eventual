//
//  IconBarButtonItemTests.swift
//  Eventual
//
//  Created by Peng Wang on 12/14/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

class IconBarButtonItemTests: XCTestCase {

    var item: IconBarButtonItem!

    override func setUp() {
        super.setUp()
        item = IconBarButtonItem()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(item.state == .Normal)
    }

    func testToggleActiveState() {
        item.toggleState(.Active, on: true)
        XCTAssertTrue(item.state == .Active, "Toggles on.")

        item.toggleState(.Filled, on: true)
        XCTAssertTrue(item.state == .Active, "Fails toggling on for other non-normal states.")

        item.toggleState(.Active, on: false)
        XCTAssertTrue(item.state == .Normal, "Toggles off.")
    }

    func testToggleFilledState() {
        item.toggleState(.Filled, on: true)
        XCTAssertTrue(item.state == .Filled, "Toggles on.")

        item.toggleState(.Active, on: true)
        XCTAssertTrue(item.state == .Filled, "Fails toggling on for other non-normal states.")

        item.toggleState(.Filled, on: false)
        XCTAssertTrue(item.state == .Normal, "Toggles off.")
    }

    func testToggleSuccessfulState() {
        item.toggleState(.Successful, on: true)
        XCTAssertTrue(item.state == .Successful, "Toggles on.")

        item.toggleState(.Successful, on: false)
        XCTAssertTrue(item.state == .Normal, "Toggles off.")
    }

}
