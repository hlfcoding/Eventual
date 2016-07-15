//
//  NavigationCoordinatorTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

import EventKit
import MapKit
import HLFMapViewController

final class NavigationCoordinatorTests: XCTestCase {

    class TestNavigationCoordinator: NavigationCoordinator {

        var presentedViewController: UIViewController?
        var dismissedViewController: UIViewController?

        override func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
            presentedViewController = viewController
        }
        override func dismissViewControllerAnimated(animated: Bool, completion: (() -> Void)?) {
            dismissedViewController = currentViewController
        }
        override func modalMapViewController() -> NavigationViewController {
            return TestMapModalViewController()
        }

    }
    class StubbedTestEvent: TestEvent {

        override func fetchLocationMapItemIfNeeded(completionHandler: (MKMapItem?, NSError?) -> Void) {
            completionHandler(MKMapItem(), nil)
        }
        
    }
    class TestEventViewControllerState: NSObject, EventViewControllerState { var event: Event! }
    class TestMapModalViewController: NavigationViewController {}

    var coordinator: TestNavigationCoordinator!
    override func setUp() {
        super.setUp()
        coordinator = TestNavigationCoordinator()
    }

    func testPresentingMapModalOnLocationButtonTap() {
        let testState = TestEventViewControllerState()
        let testEvent = StubbedTestEvent()
        testState.event = testEvent
        coordinator.handleLocationButtonTapFromEventViewController(testState)
        XCTAssertTrue(coordinator.presentedViewController is TestMapModalViewController, "Presents modal.")

        testEvent.location = "Some Place"
        coordinator.handleLocationButtonTapFromEventViewController(testState)
        XCTAssertNotNil(coordinator.selectedLocationState.mapItem, "First gets the CLPlacemark and builds the MKMapItem from location string.")
        XCTAssertTrue(coordinator.presentedViewController is TestMapModalViewController, "Then presents modal.")
    }

    func testDismissingMapModalOnMapItemSelection() {
        coordinator.mapViewController(MapViewController(), didSelectMapItem: MKMapItem())
        XCTAssertNotNil(coordinator.selectedLocationState.mapItem, "Updates state.")
        XCTAssertEqual(coordinator.dismissedViewController, coordinator.currentViewController, "Dismisses modal.")
    }

}
