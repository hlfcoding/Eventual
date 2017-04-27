//
//  EventNavigationController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit
import EventKitUI
import MapKit
import HLFMapViewController

class EventNavigationController: FlowNavigationController {

    fileprivate weak var eventScreen: EventScreen?
    fileprivate var selectedLocationState: (mapItem: MKMapItem?, event: Event?) = (nil, nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        Action.restoreEvent.verify(performer: self)
        Action.showEventLocation.verify(performer: self)
        Action.showSystemEventEditor.verify(performer: self)
    }

    private func unpackEventScreenAction(sender: Any?) -> (EventScreen, Event) {
        let eventScreen = sender as! EventScreen
        let event = eventScreen.event!
        self.eventScreen = eventScreen
        return (eventScreen, event)
    }

    // MARK: - Actions

    func restoreEvent(_ sender: Any?) {
        let dataSource = self.dataSource!
        let eventScreen = sender as! EventScreen
        let event = eventScreen.event!
        dataSource.manager.requestAccess {
            if event.isNew {
                eventScreen.event = Event(event: event, entity: dataSource.manager.newEntity())
            } else if let identifier = event.decodedIdentifier,
                let entity = dataSource.findEvent(identifier: identifier)?.entity {
                eventScreen.event = Event(event: event, entity: entity)
            }
        }
    }

    func showSystemEventEditor(_ sender: Any?) {
        let (_, event) = unpackEventScreenAction(sender: sender)
        let viewController = EKEventEditViewController()
        viewController.editViewDelegate = self
        viewController.event = event.entity
        viewController.eventStore = dataSource!.manager.store
        present(viewController, animated: true)
    }

    func showEventLocation(_ sender: Any?) {
        let (_, event) = unpackEventScreenAction(sender: sender)

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

extension EventNavigationController: EKEventEditViewDelegate {

    func eventEditViewController(_ controller: EKEventEditViewController,
                                 didCompleteWith action: EKEventEditViewAction) {
        let dataSource = self.dataSource!
        let eventScreen = self.eventScreen!
        var completion: (() -> Void)?
        switch action {
        case .canceled: break
        case .deleted:
            transitioningDelegate = nil
            modalPresentationStyle = .fullScreen
            completion = { self.dismiss(animated: true) }
            try! dataSource.remove(event: eventScreen.event, commit: false)
        case .saved:
            let entity = controller.event!
            eventScreen.event = Event(entity: entity)
            try! dataSource.save(event: eventScreen.event, commit: false)
        }
        controller.dismiss(animated: true, completion: completion)
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
