//
//  NavigationCoordinator.swift
//  Eventual
//
//  Created by Peng Wang on 2/12/16.
//  Copyright © 2016 Eventual App. All rights reserved.
//

import UIKit

import MapKit
import HLFMapViewController

/**
 Loose interpretation of [coordinators](http://khanlou.com/2015/10/coordinators-redux/).
 It hooks into all NavigationViewController which then allows it to be delegated navigation from
 view controllers. Unlike the article, a tree of coordinators is overkill for this app.
 */
class NavigationCoordinator: NSObject, UINavigationControllerDelegate {

    weak var currentNavigationController: UINavigationController?
    weak var currentViewController: UIViewController?

    /** Wraps `UINavigationController` method for testing. */
    func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        self.currentNavigationController?.presentViewController(viewController, animated: true, completion: nil)
    }

    /** Wraps `UIViewController` method for testing. */
    func dismissViewControllerAnimated(animated: Bool, completion: (() -> Void)? = nil) {
        self.currentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController,
         willShowViewController viewController: UIViewController, animated: Bool)
    {
        if let eventViewController = viewController as? EventViewController {
            eventViewController.delegate = self
        } else {
            return
        }
        self.currentNavigationController = navigationController
        self.currentViewController = viewController
    }

}

// MARK: - EventViewControllerDelegate

extension NavigationCoordinator: EventViewControllerDelegate {

    func handleLocationButtonTapFromEventViewController(controllerState: EventViewControllerState) {
        let event = controllerState.event

        let presentModalViewController = {
            let modal = NavigationViewController.modalMapViewControllerWithDelegate(self,
                selectedMapItem: controllerState.selectedMapItem)
            self.presentViewController(modal, animated: true)
        }

        guard !event.isNew && controllerState.selectedMapItem == nil
              else { presentModalViewController(); return }

        event.fetchLocationPlacemarkIfNeeded { (placemarks, error) in
            guard error == nil else { print(error); return }
            guard let placemark = placemarks?.first else { return } // Location could not be geocoded.

            controllerState.selectedMapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            presentModalViewController()
        }
    }

}

// MARK: - MapViewControllerDelegate

extension NavigationCoordinator: MapViewControllerDelegate {

    func mapViewController(mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
        if let eventViewControllerState = self.currentViewController as? EventViewControllerState {
            if let address = mapItem.placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
                eventViewControllerState.dataSource.changeFormDataValue(address.joinWithSeparator("\n"), atKeyPath: "location")
            }
            eventViewControllerState.selectedMapItem = mapItem
        }
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
