//
//  NavigationCoordinator.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

import EventKit
import MapKit

protocol CoordinatedViewController: NSObjectProtocol {

    weak var delegate: CoordinatedViewControllerDelegate! { get set }
    
}

protocol CoordinatedViewControllerDelegate: NSObjectProtocol {

    func prepareAddEventSegue(segue: UIStoryboardSegue)
    func prepareEditEventSegue(segue: UIStoryboardSegue, event: Event)
    func prepareShowDaySegue(segue: UIStoryboardSegue, dayDate: NSDate)

}

/**
 Loose interpretation of [coordinators](http://khanlou.com/2015/10/coordinators-redux/).
 It hooks into all `NavigationViewController` which then allows it to be delegated navigation from
 view controllers. Unlike the article, a tree of coordinators is overkill for this app.
 */
class NavigationCoordinator: NSObject, UINavigationControllerDelegate {

    weak var currentNavigationController: UINavigationController?
    weak var currentViewController: UIViewController?

    private var eventManager: EventManager { return EventManager.defaultManager }

    var selectedLocationState: (mapItem: MKMapItem?, event: Event?) = (nil, nil)

    /* testable */ func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        self.currentNavigationController?.presentViewController(viewController, animated: true, completion: nil)
    }

    /* testable */ func dismissViewControllerAnimated(animated: Bool, completion: (() -> Void)? = nil) {
        self.currentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController,
                              willShowViewController viewController: UIViewController, animated: Bool)
    {
        guard let coordinatedViewController = viewController as? CoordinatedViewController else { return }
        coordinatedViewController.delegate = self
        self.currentNavigationController = navigationController
        self.currentViewController = viewController
    }

}

// MARK: - CoordinatedViewControllerDelegate

extension NavigationCoordinator: CoordinatedViewControllerDelegate {

    func prepareAddEventSegue(segue: UIStoryboardSegue) {
        guard
            let navigationController = segue.destinationViewController as? NavigationViewController,
            let eventViewController = navigationController.topViewController as? EventViewController
            else { return }

        if let dayViewController = segue.sourceViewController as? DayViewController {
            let event = Event(entity: EKEvent(eventStore: self.eventManager.store))
            event.start(dayViewController.dayDate)
            eventViewController.event = event
            eventViewController.unwindSegueIdentifier = .UnwindToDay

        } else if segue.sourceViewController is MonthsViewController {
            eventViewController.unwindSegueIdentifier = .UnwindToMonths
        }
    }

    func prepareEditEventSegue(segue: UIStoryboardSegue, event: Event) {
        if
            let dayViewController = segue.sourceViewController as? DayViewController,
            let navigationController = segue.destinationViewController as? NavigationViewController,
            let eventViewController = navigationController.topViewController as? EventViewController
        {
            navigationController.transitioningDelegate = dayViewController.zoomTransitionTrait
            navigationController.modalPresentationStyle = .Custom
            // So form doesn't mutate shared state.
            eventViewController.event = Event(entity: event.entity)
            eventViewController.unwindSegueIdentifier = .UnwindToDay
        }
    }

    func prepareShowDaySegue(segue: UIStoryboardSegue, dayDate: NSDate) {
        if
            let monthsViewController = segue.sourceViewController as? MonthsViewController,
            let navigationController = segue.destinationViewController as? NavigationViewController,
            let dayViewController = navigationController.topViewController as? DayViewController
        {
            navigationController.transitioningDelegate = monthsViewController.zoomTransitionTrait
            navigationController.modalPresentationStyle = .Custom
            dayViewController.dayDate = dayDate
        }
    }

}
