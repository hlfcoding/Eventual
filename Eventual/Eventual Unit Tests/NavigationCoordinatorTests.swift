//
//  NavigationCoordinatorTests.swift
//  Eventual
//
//  Created by Peng Wang on 2/12/16.
//  Copyright (c) 2016 Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

import EventKit
import MapKit
import HLFMapViewController

class NavigationCoordinatorTests: XCTestCase {

    class TestNavigationCoordinator: NavigationCoordinator {

        var presentedViewController: UIViewController?
        var dismissedViewController: UIViewController?
        var updateCurrentViewControllerCallCount = 0;

        override func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
            self.presentedViewController = viewController
        }
        override func dismissViewControllerAnimated(animated: Bool, completion: (() -> Void)?) {
            self.dismissedViewController = self.currentViewController
        }
        override func modalMapViewController() -> NavigationViewController {
            return TestMapModalViewController()
        }
        override func updateCurrentViewController() {
            self.updateCurrentViewControllerCallCount += 1
        }

    }
    class TestEvent: Event {

        private var testIdentifier: String!
        override var identifier: String { return self.testIdentifier ?? self.entity.eventIdentifier }

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
        // Given:
        let testState = TestEventViewControllerState()
        let testEvent = TestEvent(entity: EKEvent(eventStore: EventManager().store))
        testState.event = testEvent
        // When:
        self.coordinator.handleLocationButtonTapFromEventViewController(testState)
        // Then:
        XCTAssertTrue(self.coordinator.presentedViewController is TestMapModalViewController, "Presents modal.")
        // Given:
        testEvent.testIdentifier = "some-id"
        // When:
        self.coordinator.handleLocationButtonTapFromEventViewController(testState)
        // Then:
        XCTAssertNotNil(self.coordinator.selectedMapItem, "First gets the CLPlacemark and builds the MKMapItem from location string.")
        XCTAssertTrue(self.coordinator.presentedViewController is TestMapModalViewController, "Then presents modal.")
    }

    func testDismissingMapModalOnMapItemSelection() {
        self.coordinator.mapViewController(MapViewController(), didSelectMapItem: MKMapItem())
        XCTAssertNotNil(self.coordinator.selectedMapItem, "Updates state.")
        XCTAssertEqual(self.coordinator.updateCurrentViewControllerCallCount, 1, "Updates currentViewController state.")
        XCTAssertEqual(self.coordinator.dismissedViewController, self.coordinator.currentViewController, "Dismisses modal.")
    }


}
