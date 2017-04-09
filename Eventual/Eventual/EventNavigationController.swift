//
//  EventNavigationController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import MapKit
import HLFMapViewController

class EventNavigationController: UINavigationController {

    fileprivate weak var eventScreen: EventScreen?
    fileprivate var selectedLocationState: (mapItem: MKMapItem?, event: Event?) = (nil, nil)

    // MARK: - Actions

    func showEventLocation(_ sender: Any?) {
        let eventScreen = sender as! EventScreen
        self.eventScreen = eventScreen
        let event = eventScreen.event!

        let presentModalViewController = {
            let viewController = MapViewController.modalMapViewController(
                delegate: self, selectedMapItem: self.selectedLocationState.mapItem
            )
            self.present(viewController, animated: true)
        }

        if !event.hasLocation {
            return presentModalViewController()

        } else if let selectedEvent = selectedLocationState.event, event == selectedEvent {
            return presentModalViewController()
        }

        event.fetchLocationMapItemIfNeeded { (mapItem, error) in
            guard error == nil, let mapItem = mapItem else {
                NSLog("Error fetching location: \(error!)")
                return
            }
            self.selectedLocationState = (mapItem: mapItem, event: event)
            presentModalViewController()
        }
    }

}

extension EventNavigationController: MapViewControllerDelegate {

    func mapViewController(_ mapViewController: MapViewController,
                           didSelectMapItem mapItem: MKMapItem) {
        selectedLocationState.mapItem = mapItem
        eventScreen!.updateLocation(mapItem: mapItem)
        dispatchAfter(1) {
            self.dismiss(animated: true)
        }
    }

    func mapViewController(_ mapViewController: MapViewController,
                           didDeselectMapItem mapItem: MKMapItem) {
        if mapItem.name == selectedLocationState.mapItem?.name {
            selectedLocationState.mapItem = nil
        }
        eventScreen!.updateLocation(mapItem: nil)
        if !mapViewController.hasResults {
            dispatchAfter(1) {
                self.dismiss(animated: true)
            }
        }
    }

    func resultsViewController(_ resultsViewController: SearchResultsViewController,
                               didConfigureResultViewCell cell: SearchResultsViewCell,
                               withMapItem mapItem: MKMapItem) {
        Appearance.configureSearchResult(cell: cell, table: resultsViewController.tableView)
    }

    func dismissModalMapViewController(_ sender: Any?) {
        dismiss(animated: true)
    }

}
