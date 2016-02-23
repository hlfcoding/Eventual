//
//  NavigationCoordinator.swift
//  Eventual
//
//  Created by Peng Wang on 2/12/16.
//  Copyright (c) 2016 Eventual App. All rights reserved.
//

import UIKit

import EventKit
import MapKit
import HLFMapViewController

protocol CoordinatedViewController: NSObjectProtocol {

    weak var delegate: ViewControllerDelegate! { get set }
    
}

protocol ViewControllerDelegate: NSObjectProtocol {

    func handleLocationButtonTapFromEventViewController(controllerState: EventViewControllerState)
    
    func prepareAddEventSegue(segue: UIStoryboardSegue)
    func prepareEditEventSegue(segue: UIStoryboardSegue, event: Event)
    func prepareShowDaySegue(segue: UIStoryboardSegue, dayDate: NSDate)

}

/**
 Loose interpretation of [coordinators](http://khanlou.com/2015/10/coordinators-redux/).
 It hooks into all NavigationViewController which then allows it to be delegated navigation from
 view controllers. Unlike the article, a tree of coordinators is overkill for this app.
 */
class NavigationCoordinator: NSObject, UINavigationControllerDelegate {

    weak var currentNavigationController: UINavigationController?
    weak var currentViewController: UIViewController?

    private var eventManager: EventManager { return EventManager.defaultManager }

    var selectedMapItem: MKMapItem?

    /** Wraps `UINavigationController` method for testing. */
    func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        self.currentNavigationController?.presentViewController(viewController, animated: true, completion: nil)
    }

    /** Wraps `UIViewController` method for testing. */
    func dismissViewControllerAnimated(animated: Bool, completion: (() -> Void)? = nil) {
        self.currentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    /** Wraps `NavigationViewController` method for testing. */
    func modalMapViewController() -> NavigationViewController {
        return NavigationViewController.modalMapViewControllerWithDelegate( self,
            selectedMapItem: self.selectedMapItem
        );
    }

    func updateCurrentViewController() {
        if let eventViewController = self.currentViewController as? EventViewController,
               address = self.selectedMapItem?.placemark.addressDictionary?["FormattedAddressLines"] as? [String]
        {
            eventViewController.dataSource.changeFormDataValue(address.joinWithSeparator("\n"), atKeyPath: "location")
        }
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

// MARK: - ViewControllerDelegate

extension NavigationCoordinator: ViewControllerDelegate {

    func handleLocationButtonTapFromEventViewController(controllerState: EventViewControllerState) {
        let event = controllerState.event

        let presentModalViewController = {
            self.presentViewController(self.modalMapViewController(), animated: true)
        }

        guard !event.isNew && self.selectedMapItem == nil
              else { presentModalViewController(); return }

        event.fetchLocationMapItemIfNeeded { (mapItem, error) in
            guard error == nil else { print(error); return }
            self.selectedMapItem = mapItem
            presentModalViewController()
        }
    }

    func prepareAddEventSegue(segue: UIStoryboardSegue) {
        guard let navigationController = segue.destinationViewController as? NavigationViewController,
                  eventViewController = navigationController.topViewController as? EventViewController
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
        if let dayViewController = segue.sourceViewController as? DayViewController,
               navigationController = segue.destinationViewController as? NavigationViewController,
               eventViewController = navigationController.topViewController as? EventViewController
        {
            navigationController.transitioningDelegate = dayViewController.zoomTransitionTrait
            navigationController.modalPresentationStyle = .Custom
            // So form doesn't mutate shared state.
            eventViewController.event = Event(entity: event.entity)
            eventViewController.unwindSegueIdentifier = .UnwindToDay
        }
    }

    func prepareShowDaySegue(segue: UIStoryboardSegue, dayDate: NSDate) {
        if let monthsViewController = segue.sourceViewController as? MonthsViewController,
               navigationController = segue.destinationViewController as? NavigationViewController,
               dayViewController = navigationController.topViewController as? DayViewController
        {
            navigationController.transitioningDelegate = monthsViewController.zoomTransitionTrait
            navigationController.modalPresentationStyle = .Custom
            dayViewController.dayDate = dayDate
        }
    }

}

// MARK: - MapViewControllerDelegate

extension NavigationCoordinator: MapViewControllerDelegate {

    func mapViewController(mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
        self.selectedMapItem = mapItem
        self.updateCurrentViewController()
        self.dismissViewControllerAnimated(true)
    }

    func resultsViewController(resultsViewController: SearchResultsViewController,
         didConfigureResultViewCell cell: SearchResultsViewCell, withMapItem mapItem: MKMapItem)
    {
        AppearanceManager.defaultManager.customizeAppearanceOfSearchResults(resultsViewController, andCell: cell)
    }

    func dismissModalMapViewController(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true)
    }
}
