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
    private func ensureDismissalOfContainer(container: UINavigationController) {
        guard isCurrentItemRemoved else { return }
        container.transitioningDelegate = nil
        container.modalPresentationStyle = .FullScreen
    }

    private func prepareContainerForPresentation(container: UINavigationController, sender: AnyObject?) {
        container.modalPresentationStyle = .Custom
        container.transitioningDelegate = zoomTransitionTrait
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
 Loose interpretation of [coordinators](http://khanlou.com/2015/10/coordinators-redux/) to contain
 flow logic. It explicitly attaches itself to `CoordinatedViewController`s and `UINavigationController`s
 during segue preparation, but should be manually attached during initialization or manual presenting
 of external view-controllers. Unlike the article, a tree of coordinators is overkill for us.
 */
final class NavigationCoordinator: NSObject, NavigationCoordinatorProtocol, UINavigationControllerDelegate,

MapViewControllerDelegate {

    // MARK: State

    weak var currentContainer: UINavigationController?
    weak var currentScreen: UIViewController?

    var eventManager: EventManager!
    var selectedLocationState: (mapItem: MKMapItem?, event: Event?) = (nil, nil)

    private var isFetchingUpcomingEvents = false
    private var appDidBecomeActiveObserver: NSObjectProtocol!

    init(eventManager: EventManager) {
        super.init()
        self.eventManager = eventManager

        appDidBecomeActiveObserver = NSNotificationCenter.defaultCenter().addObserverForName(
            UIApplicationDidBecomeActiveNotification, object: nil, queue: nil,
            usingBlock: { _ in self.startUpcomingEventsFlow() })
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(appDidBecomeActiveObserver)
    }

    // MARK: Data

    func startUpcomingEventsFlow() {
        let center = NSNotificationCenter.defaultCenter()
        var observer: NSObjectProtocol?
        observer = center.addObserverForName(EntityAccessNotification, object: nil, queue: nil) {
            guard let
                payload = $0.userInfo?.notificationUserInfoPayload() as? EntityAccessPayload,
                result = payload.result where result == .Granted
                else { return }

            self.fetchUpcomingEvents {
                guard let observer = observer else { return }
                center.removeObserver(observer)
            }
        }
        if !eventManager.requestAccessIfNeeded() {
            self.fetchUpcomingEvents(nil)
        }
    }

    private func fetchUpcomingEvents(callback: (() -> Void)?) {
        guard !isFetchingUpcomingEvents else { return }
        isFetchingUpcomingEvents = true
        let completion = {
            self.isFetchingUpcomingEvents = false
            callback?()
        }
        let componentsToAdd = NSDateComponents(); componentsToAdd.year = 1
        let endDate = NSCalendar.currentCalendar().dateByAddingComponents(
            componentsToAdd, toDate: NSDate(), options: [])!

        do {
            try eventManager.fetchEventsFromDate(untilDate: endDate, completion: completion)
        } catch {
            completion()
        }
    }
    
    // MARK: Helpers

    /* testable */ func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        currentContainer?.presentViewController(viewController, animated: animated, completion: completion)
    }

    /* testable */ func dismissViewControllerAnimated(animated: Bool, completion: (() -> Void)? = nil) {
        currentScreen?.dismissViewControllerAnimated(animated, completion: completion)
    }

    /* testable */ func modalMapViewController() -> UINavigationController {
        let navigationController = MapViewController.modalMapViewControllerWithDelegate(
            self, selectedMapItem: selectedLocationState.mapItem)
        return navigationController
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController,
                              willShowViewController viewController: UIViewController, animated: Bool) {
        currentContainer = navigationController
        currentScreen = viewController
    }

    // MARK: NavigationCoordinatorProtocol

    var monthsEvents: MonthsEvents? { return eventManager.monthsEvents }

    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier, type = Segue(rawValue: identifier) else { return }

        if let navigationController = segue.destinationViewController as? UINavigationController {
            navigationController.delegate = self
        }
        switch (type, segue.destinationViewController, segue.sourceViewController) {

        case (.AddEvent, let container as UINavigationController, let source):
            guard let eventScreen = container.topViewController as? EventScreen else { break }
            eventScreen.coordinator = self
            eventScreen.event = Event(entity: EKEvent(eventStore: eventManager.store))
            switch source {

            case let dayScreen as DayScreen:
                eventScreen.event.start(dayScreen.dayDate)
                eventScreen.unwindSegueIdentifier = Segue.UnwindToDay.rawValue
                dayScreen.currentIndexPath = nil

            case let monthsScreen as MonthsScreen:
                eventScreen.event.start()
                eventScreen.unwindSegueIdentifier = Segue.UnwindToMonths.rawValue
                monthsScreen.currentIndexPath = nil

            default: fatalError("Unsupported source.")
            }

        case (.EditEvent, let container as UINavigationController, let dayScreen as DayScreen):
            guard let eventScreen = container.topViewController as? EventScreen,
                event = dayScreen.selectedEvent
                else { return }

            dayScreen.prepareContainerForPresentation(container, sender: sender)
            eventScreen.coordinator = self
            eventScreen.event = Event(entity: event.entity) // So form doesn't mutate shared state.
            eventScreen.unwindSegueIdentifier = Segue.UnwindToDay.rawValue

        case (.ShowDay, let container as UINavigationController, let monthsScreen as MonthsScreen):
            guard let dayScreen = container.topViewController as? DayScreen else { break }

            monthsScreen.prepareContainerForPresentation(container, sender: sender)
            monthsScreen.currentSelectedDayDate = monthsScreen.selectedDayDate
            dayScreen.coordinator = self
            dayScreen.dayDate = monthsScreen.currentSelectedDayDate

        case (.UnwindToDay, let dayScreen as DayScreen, let source):
            guard let container = source.navigationController else { break }

            dayScreen.currentSelectedEvent = dayScreen.selectedEvent
            dayScreen.ensureDismissalOfContainer(container)

        case (.UnwindToMonths, let monthsScreen as MonthsScreen, let source):
            guard let container = source.navigationController else { break }

            monthsScreen.ensureDismissalOfContainer(container)

        default: fatalError("Unsupported segue.")
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

    func removeDayEvents(events: [Event]) throws {
        do {
            try eventManager.removeEvents(events)
        }
    }

    func removeEvent(event: Event) throws {
        do {
            let snapshot = Event(entity: event.entity, snapshot: true)
            var fromIndexPath: NSIndexPath?
            if let monthsEvents = monthsEvents {
                fromIndexPath = monthsEvents.indexPathForDayOfDate(snapshot.startDate)
            }

            try eventManager.removeEvents([event])

            let presave: PresavePayloadData = (snapshot, fromIndexPath, nil)
            let userInfo = EntityUpdatedPayload(event: nil, presave: presave).userInfo
            NSNotificationCenter.defaultCenter()
                .postNotificationName(EntityUpdateOperationNotification, object: nil, userInfo: userInfo)
        }
    }

    func saveEvent(event: Event) throws {
        do {
            event.calendar = event.calendar ?? eventManager.store.defaultCalendarForNewEvents
            event.prepare()
            try event.validate()

            let snapshot = event.snapshot()
            var fromIndexPath: NSIndexPath?, toIndexPath: NSIndexPath?
            if let monthsEvents = monthsEvents {
                fromIndexPath = monthsEvents.indexPathForDayOfDate(snapshot.startDate)
                toIndexPath = monthsEvents.indexPathForDayOfDate(event.startDate)
            }

            event.commitChanges()

            try eventManager.saveEvent(event)

            let presave: PresavePayloadData = (snapshot, fromIndexPath, toIndexPath)
            let userInfo = EntityUpdatedPayload(event: event, presave: presave).userInfo
            NSNotificationCenter.defaultCenter()
                .postNotificationName(EntityUpdateOperationNotification, object: nil, userInfo: userInfo)
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
