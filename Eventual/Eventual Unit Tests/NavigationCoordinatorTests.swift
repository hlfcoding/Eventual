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
            self.presentedViewController = viewController
        }
        override func dismissViewControllerAnimated(animated: Bool, completion: (() -> Void)?) {
            self.dismissedViewController = self.currentViewController
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
        self.coordinator = TestNavigationCoordinator()
    }

    func testPresentingMapModalOnLocationButtonTap() {
        let testState = TestEventViewControllerState()
        let testEvent = StubbedTestEvent()
        testState.event = testEvent
        self.coordinator.handleLocationButtonTapFromEventViewController(testState)
        XCTAssertTrue(self.coordinator.presentedViewController is TestMapModalViewController, "Presents modal.")

        testEvent.location = "Some Place"
        self.coordinator.handleLocationButtonTapFromEventViewController(testState)
        XCTAssertNotNil(self.coordinator.selectedLocationState.mapItem, "First gets the CLPlacemark and builds the MKMapItem from location string.")
        XCTAssertTrue(self.coordinator.presentedViewController is TestMapModalViewController, "Then presents modal.")
    }

    func testDismissingMapModalOnMapItemSelection() {
        self.coordinator.mapViewController(MapViewController(), didSelectMapItem: MKMapItem())
        XCTAssertNotNil(self.coordinator.selectedLocationState.mapItem, "Updates state.")
        XCTAssertEqual(self.coordinator.dismissedViewController, self.coordinator.currentViewController, "Dismisses modal.")
    }

}
