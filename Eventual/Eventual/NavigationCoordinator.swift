//
//  NavigationCoordinator.swift
//  Eventual
//
//  Created by Peng Wang on 2/12/16.
//  Copyright (c) 2016 Eventual App. All rights reserved.
//

import UIKit

import MapKit
import HLFMapViewController

protocol CoordinatedViewController: NSObjectProtocol {

    weak var delegate: ViewControllerDelegate! { get set }
    
}

protocol ViewControllerDelegate: NSObjectProtocol {

    func handleLocationButtonTapFromEventViewController(controllerState: EventViewControllerState)
    
}

/**
 Loose interpretation of [coordinators](http://khanlou.com/2015/10/coordinators-redux/).
 It hooks into all NavigationViewController which then allows it to be delegated navigation from
 view controllers. Unlike the article, a tree of coordinators is overkill for this app.
 */
class NavigationCoordinator: NSObject, UINavigationControllerDelegate {

    weak var currentNavigationController: UINavigationController?
    weak var currentViewController: UIViewController?

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
