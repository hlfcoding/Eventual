//
//  NavigationCoordinatorTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class NavigationCoordinatorTests: XCTestCase {

    var coordinator: NavigationCoordinator!

    override func setUp() {
        super.setUp()
        coordinator = NavigationCoordinator(eventManager: EventManager())
    }

}
