//
//  NavigationCoordinator.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

import EventKit
import MapKit
import HLFMapViewController

extension CoordinatedCollectionViewController {

    /** Just do the default transition if the `snapshotReferenceView` is illegitimate. */
    private func ensureDismissalOfContainer(container: NavigationViewController) {
        guard isCurrentItemRemoved else { return }
        container.transitioningDelegate = nil
        container.modalPresentationStyle = .FullScreen
    }

    private func prepareContainerForPresentation(container: NavigationViewController, sender: AnyObject?) {
        container.modalPresentationStyle = .Custom
        container.transitioningDelegate = zoomTransitionTrait
        if sender is UICollectionViewCell {
            zoomTransitionTrait.isInteractive = false
        }
    }

}

// MARK: Segues & Actions

private enum Segue: String {

    case AddEvent, EditEvent, ShowDay

    // MARK: Unwind Segues
    // Why have these if our IA is shallow and lacks the need to go back more than one screen?
    // Because we use a custom view as a 'back button', meaning it's a fake, since backBarButtonItem
    // can't be customized to a view.
    case UnwindToDay, UnwindToMonths

    static func fromActionTrigger(trigger: NavigationActionTrigger, viewController: CoordinatedViewController) -> Segue? {
        switch (trigger, viewController) {
        case (.BackgroundTap, is DayScreen),
             (.BackgroundTap, is MonthsScreen): return .AddEvent
        case (.InteractiveTransitionBegin, is DayScreen): return .EditEvent
        case (.InteractiveTransitionBegin, is MonthsScreen): return .ShowDay
        default: return nil
        }
    }

}

private enum Action {

    case ShowEventLocation

    static func fromTrigger(trigger: NavigationActionTrigger, viewController: CoordinatedViewController) -> Action? {
        switch (trigger, viewController) {
        case (.LocationButtonTap, is EventScreen): return .ShowEventLocation
        default: return nil
        }
    }

}

/**
 Loose interpretation of [coordinators](http://khanlou.com/2015/10/coordinators-redux/).
 It hooks into all `NavigationViewController` which then allows it to be delegated navigation from
 view controllers. Unlike the article, a tree of coordinators is overkill for this app.
 */
final class NavigationCoordinator: NSObject, NavigationCoordinatorProtocol, UINavigationControllerDelegate,

MapViewControllerDelegate {

    // MARK: State

    weak var currentContainer: UINavigationController?
    weak var currentScreen: UIViewController?

    var selectedLocationState: (mapItem: MKMapItem?, event: Event?) = (nil, nil)

    // MARK: Helpers

    /* testable */ func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        currentContainer?.presentViewController(viewController, animated: true, completion: nil)
    }

    /* testable */ func dismissViewControllerAnimated(animated: Bool, completion: (() -> Void)? = nil) {
        currentScreen?.dismissViewControllerAnimated(true, completion: nil)
    }

    /* testable */ func modalMapViewController() -> NavigationViewController {
        return MapViewController.modalMapViewControllerWithDelegate(
            self, selectedMapItem: selectedLocationState.mapItem)
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController,
                              willShowViewController viewController: UIViewController, animated: Bool) {
        guard let coordinatedViewController = viewController as? CoordinatedViewController else { return }
        coordinatedViewController.coordinator = self
        currentContainer = navigationController
        currentScreen = viewController
    }

    // MARK: NavigationCoordinatorProtocol

    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let rawIdentifier = segue.identifier, identifier = Segue(rawValue: rawIdentifier) else { return }
        switch identifier {

        case .AddEvent:
            guard let
                container = segue.destinationViewController as? NavigationViewController,
                eventScreen = container.topViewController as? EventScreen
                else { break }
            switch segue.sourceViewController {

            case let dayScreen as DayScreen:
                eventScreen.event = dayScreen.newDayEvent()
                eventScreen.unwindSegueIdentifier = Segue.UnwindToDay.rawValue
                dayScreen.currentIndexPath = nil

            case let monthsScreen as MonthsScreen:
                eventScreen.unwindSegueIdentifier = Segue.UnwindToMonths.rawValue
                monthsScreen.currentIndexPath = nil

            default: fatalError("Unsupported source.")
            }

        case .EditEvent:
            guard let
                container = segue.destinationViewController as? NavigationViewController,
                dayScreen = segue.sourceViewController as? DayScreen,
                event = dayScreen.selectedEvent,
                eventScreen = container.topViewController as? EventScreen
                else { return }

            dayScreen.prepareContainerForPresentation(container, sender: sender)
            eventScreen.event = Event(entity: event.entity) // So form doesn't mutate shared state.
            eventScreen.unwindSegueIdentifier = Segue.UnwindToDay.rawValue

        case .ShowDay:
            guard let
                container = segue.destinationViewController as? NavigationViewController,
                dayScreen = container.topViewController as? DayScreen,
                monthsScreen = segue.sourceViewController as? MonthsScreen
                else { break }

            monthsScreen.prepareContainerForPresentation(container, sender: sender)
            monthsScreen.currentSelectedDayDate = monthsScreen.selectedDayDate
            dayScreen.dayDate = monthsScreen.currentSelectedDayDate

        case .UnwindToDay:
            guard let
                container = segue.sourceViewController.navigationController as? NavigationViewController,
                dayScreen = segue.destinationViewController as? DayScreen
                else { break }

            dayScreen.currentSelectedEvent = dayScreen.selectedEvent
            EventManager.defaultManager.updateEventsByMonthsAndDays() // FIXME
            dayScreen.updateData(andReload: true)
            dayScreen.ensureDismissalOfContainer(container)

        case .UnwindToMonths:
            guard let
                container = segue.sourceViewController.navigationController as? NavigationViewController,
                monthsScreen = segue.destinationViewController as? MonthsScreen
                else { break }
            monthsScreen.ensureDismissalOfContainer(container)
        }
    }

    func performNavigationActionForTrigger(trigger: NavigationActionTrigger,
                                           viewController: CoordinatedViewController) {
        guard let performer = viewController as? UIViewController else { return }
        if let segue = Segue.fromActionTrigger(trigger, viewController: viewController) {
            performer.performSegueWithIdentifier(segue.rawValue, sender: self)
            return
        }

        guard let action = Action.fromTrigger(trigger, viewController: viewController)
            else { preconditionFailure("Unsupported trigger.") }
        switch action {

        case .ShowEventLocation:
            guard let eventScreen = viewController as? EventScreen else { preconditionFailure() }
            let event = eventScreen.event
            let presentModalViewController = {
                self.presentViewController(self.modalMapViewController(), animated: true)
            }

            if !event.hasLocation {
                return presentModalViewController()

            } else if let selectedEvent = selectedLocationState.event where event == selectedEvent {
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

    }

    // MARK: MapViewControllerDelegate

    func mapViewController(mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
        selectedLocationState.mapItem = mapItem
        if let eventScreen = currentScreen as? EventScreen, mapItem = selectedLocationState.mapItem {
            eventScreen.updateLocation(mapItem)
        }
        dismissViewControllerAnimated(true)
    }

    func resultsViewController(resultsViewController: SearchResultsViewController,
                               didConfigureResultViewCell cell: SearchResultsViewCell, withMapItem mapItem: MKMapItem) {
        Appearance.configureCell(cell, table: resultsViewController.tableView)
    }

    func dismissModalMapViewController(sender: AnyObject?) {
        dismissViewControllerAnimated(true)
    }

}
