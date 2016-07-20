//
//  EventLocationModal.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

import MapKit
import HLFMapViewController

class EventLocationModal {

    // NOTE: This would normally be done in a storyboard, but the latter fails to auto-load the xib.
    static func modalMapViewControllerWithDelegate(delegate: MapViewControllerDelegate,
                                                   selectedMapItem: MKMapItem? = nil) -> NavigationViewController {
        let dismissalSelector = #selector(NavigationCoordinator.dismissViewControllerAnimated(_:completion:))
        guard delegate.respondsToSelector(dismissalSelector) else { preconditionFailure("Needs to implement \(dismissalSelector).") }

        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.delegate = delegate
        mapViewController.selectedMapItem = selectedMapItem

        mapViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Label.NavigationBack.rawValue, style: .Plain, target: delegate, action: dismissalSelector
        )
        mapViewController.customizeNavigationItem()

        let navigationController = NavigationViewController(rootViewController: mapViewController)
        return navigationController
    }

}

protocol EventViewControllerDelegate: CoordinatedViewControllerDelegate {

    func handleLocationButtonTapFromEventViewController(controllerState: EventViewControllerState)

}

extension NavigationCoordinator: EventViewControllerDelegate {

    func handleLocationButtonTapFromEventViewController(controllerState: EventViewControllerState) {
        let event = controllerState.event

        let presentModalViewController = {
            self.presentViewController(self.modalMapViewController(), animated: true)
        }

        guard event.hasLocation else { return presentModalViewController() }

        if let selectedEvent = selectedLocationState.event where event == selectedEvent {
            return presentModalViewController()
        }

        event.fetchLocationMapItemIfNeeded { (mapItem, error) in
            guard error == nil, let mapItem = mapItem else {
                NSLog("Error fetching location: \(error)")
                return
            }
            self.selectedLocationState = (mapItem: mapItem, event: event)
            presentModalViewController()
        }
    }

    /* testable */ func modalMapViewController() -> NavigationViewController {
        return EventLocationModal.modalMapViewControllerWithDelegate(
            self, selectedMapItem: selectedLocationState.mapItem)
    }

}

extension NavigationCoordinator: MapViewControllerDelegate {

    func mapViewController(mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
        selectedLocationState.mapItem = mapItem

        if let
            eventViewController = currentViewController as? EventViewController,
            address = selectedLocationState.mapItem?.placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
            eventViewController.dataSource.changeFormDataValue(address.joinWithSeparator("\n"), atKeyPath: "location")
        }

        dismissViewControllerAnimated(true)
    }

    func resultsViewController(resultsViewController: SearchResultsViewController,
                               didConfigureResultViewCell cell: SearchResultsViewCell, withMapItem mapItem: MKMapItem) {
        // NOTE: Regarding custom cell select and highlight background color, it
        // would still not match other cells' select behaviors. The only chance of
        // getting consistency seems to be copying the extensions in CollectionViewTileCell
        // to a SearchResultsViewCell subclass. This would also require references
        // for contentView edge constraints, and allow cell class to be customized.

        var customMargins = cell.contentView.layoutMargins
        customMargins.top = 20
        customMargins.bottom = 20
        cell.contentView.layoutMargins = customMargins
        resultsViewController.tableView.rowHeight = 60

        cell.customTextLabel.font = UIFont.systemFontOfSize(17)
    }

    func dismissModalMapViewController(sender: AnyObject?) {
        dismissViewControllerAnimated(true)
    }

}
