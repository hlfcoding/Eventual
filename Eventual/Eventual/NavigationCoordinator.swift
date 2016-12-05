//
//  NavigationCoordinator.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

import EventKit
import EventKitUI
import MapKit
import HLFMapViewController

// MARK: Segues & Actions

private enum Segue: String {

    case addEvent = "AddEvent"
    case editEvent = "EditEvent"
    case showDay = "ShowDay"

    // MARK: Unwind Segues
    // Why have these if our IA is shallow and lacks the need to go back more than one screen?
    // Because we use a custom view as a 'back button', meaning it's a fake, since backBarButtonItem
    // can't be customized to a view.
    case unwindToDay = "UnwindToDay"
    case unwindToMonths = "UnwindToMonths"

    static func from(trigger: NavigationActionTrigger,
                     viewController: CoordinatedViewController) -> Segue? {
        switch (trigger, viewController) {
        case (.backgroundTap, is DayScreen),
             (.backgroundTap, is MonthsScreen): return .addEvent
        case (.manualDismissal, is DayScreen): return .unwindToMonths
        case (.manualDismissal, let eventScreen as EventScreen):
            return Segue(rawValue: eventScreen.unwindSegueIdentifier!)
        default: return nil
        }
    }

}

private enum Action {

    case showEventLocation, showEKEditViewController

    static func from(trigger: NavigationActionTrigger,
                     viewController: CoordinatedViewController) -> Action? {
        switch (trigger, viewController) {
        case (.editInCalendarAppTap, is EventScreen): return .showEKEditViewController
        case (.locationButtonTap, is EventScreen): return .showEventLocation
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

EKEventEditViewDelegate, MapViewControllerDelegate {

    // MARK: State

    weak var currentContainer: UINavigationController?
    weak var currentScreen: UIViewController?

    var eventManager: EventManager!
    var hasCalendarAccess = false
    var pastEvents: PastEvents!
    var upcomingEvents: UpcomingEvents!
    var selectedLocationState: (mapItem: MKMapItem?, event: Event?) = (nil, nil)

    private var appDidBecomeActiveObserver: NSObjectProtocol!

    init(eventManager: EventManager) {
        super.init()
        self.eventManager = eventManager
        self.pastEvents = PastEvents(manager: eventManager)
        self.upcomingEvents = UpcomingEvents(manager: eventManager)

        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidBecomeActive, object: nil, queue: nil,
            using: { _ in self.startUpcomingEventsFlow(completion: self.startPastEventsFlow) }
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(appDidBecomeActiveObserver)
    }

    // MARK: Data

    func startPastEventsFlow() {
        guard hasCalendarAccess else { preconditionFailure() }
        pastEvents.fetch {
            print("Past events months: \(self.pastEvents.events?.months.count)")
        }
    }

    func startUpcomingEventsFlow(completion: (() -> Void)?) {
        var observer: NSObjectProtocol?
        observer = NotificationCenter.default.addObserver(
            forName: .EntityAccess, object: nil, queue: nil
        ) {
            guard let payload = $0.userInfo?.notificationUserInfoPayload() as? EntityAccessPayload,
                payload.result == .granted
                else { return }

            self.hasCalendarAccess = true
            self.upcomingEvents.fetch {
                guard let observer = observer else { return }
                NotificationCenter.default.removeObserver(observer)
                completion?()
            }
        }
        if !eventManager.requestAccessIfNeeded() {
            upcomingEvents.fetch(completion: completion)
        }
    }

    // MARK: Helpers

    /* testable */ func present(viewController: UIViewController, animated: Bool,
                                completion: (() -> Void)? = nil) {
        currentContainer?.present(viewController, animated: animated, completion: completion)
    }

    /* testable */ func dismissViewController(animated: Bool, completion: (() -> Void)? = nil) {
        currentScreen?.dismiss(animated: animated, completion: completion)
    }

    /* testable */ func modalMapViewController() -> UINavigationController {
        let navigationController = MapViewController.modalMapViewController(
            delegate: self, selectedMapItem: selectedLocationState.mapItem
        )
        return navigationController
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        guard !isRestoringState else { return }
        currentContainer = navigationController
        currentScreen = viewController
    }

    // MARK: NavigationCoordinatorProtocol

    var isRestoringState = false {
        didSet {
            guard isRestoringState else { return }
            startUpcomingEventsFlow() {
                guard let currentScreen = self.currentScreen as? CoordinatedViewController else { return }
                currentScreen.finishRestoringState()
                self.isRestoringState = false
            }
        }
    }
    var monthsEvents: MonthsEvents? { return upcomingEvents.events }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let type = Segue(rawValue: identifier) else { return }

        if let navigationController = segue.destination as? UINavigationController {
            navigationController.delegate = self
        }
        switch (type, segue.destination, segue.source) {

        case (.addEvent, let container as UINavigationController, let source):
            guard let eventScreen = container.topViewController as? EventScreen else { break }
            eventScreen.coordinator = self
            eventScreen.event = eventManager.newEvent()
            switch source {

            case let dayScreen as DayScreen:
                eventScreen.event.start(date: dayScreen.dayDate)
                eventScreen.unwindSegueIdentifier = Segue.unwindToDay.rawValue
                dayScreen.currentIndexPath = nil

            case let monthsScreen as MonthsScreen:
                eventScreen.event.start(date: monthsScreen.currentSelectedMonthDate)
                eventScreen.unwindSegueIdentifier = Segue.unwindToMonths.rawValue
                monthsScreen.currentIndexPath = nil

            default: fatalError("Unsupported source.")
            }

        case (.editEvent, let container as UINavigationController, let dayScreen as DayScreen):
            guard let eventScreen = container.topViewController as? EventScreen,
                let event = dayScreen.selectedEvent
                else { return }

            container.modalPresentationStyle = .custom
            container.transitioningDelegate = dayScreen.zoomTransitionTrait
            eventScreen.coordinator = self
            eventScreen.event = Event(entity: event.entity) // So form doesn't mutate shared state.
            eventScreen.unwindSegueIdentifier = Segue.unwindToDay.rawValue

        case (.showDay, let container as UINavigationController, let monthsScreen as MonthsScreen):
            guard let dayScreen = container.topViewController as? DayScreen else { break }

            container.modalPresentationStyle = .custom
            container.transitioningDelegate = monthsScreen.zoomTransitionTrait
            monthsScreen.currentSelectedDayDate = monthsScreen.selectedDayDate
            dayScreen.coordinator = self
            dayScreen.dayDate = monthsScreen.currentSelectedDayDate

        case (.unwindToDay, let dayScreen as DayScreen, let source):
            guard let container = source.navigationController else { break }

            dayScreen.currentSelectedEvent = dayScreen.selectedEvent
            if dayScreen.isCurrentItemRemoved {
                container.transitioningDelegate = nil
                container.modalPresentationStyle = .fullScreen
            }

        case (.unwindToMonths, let monthsScreen as MonthsScreen, let source):
            guard let container = source.navigationController else { break }

            if monthsScreen.isCurrentItemRemoved {
                container.transitioningDelegate = nil
                container.modalPresentationStyle = .fullScreen
            }

        default: fatalError("Unsupported segue.")
        }
    }

    func performNavigationAction(for trigger: NavigationActionTrigger,
                                 viewController: CoordinatedViewController) {
        guard let performer = viewController as? UIViewController else { return }
        if let segue = Segue.from(trigger: trigger, viewController: viewController) {
            if performer.shouldPerformSegue(withIdentifier: segue.rawValue, sender: self) {
                performer.performSegue(withIdentifier: segue.rawValue, sender: self)
            }
            return
        }

        guard let action = Action.from(trigger: trigger, viewController: viewController)
            else { preconditionFailure("Unsupported trigger.") }
        switch action {

        case .showEKEditViewController:
            guard let eventScreen = viewController as? EventScreen, let event = eventScreen.event
                else { preconditionFailure() }
            let viewController = EKEventEditViewController()
            viewController.editViewDelegate = self
            viewController.event = event.entity
            viewController.eventStore = eventManager.store
            self.present(viewController: viewController, animated: true)

        case .showEventLocation:
            guard let eventScreen = viewController as? EventScreen, let event = eventScreen.event
                else { preconditionFailure() }
            let presentModalViewController = {
                self.present(viewController: self.modalMapViewController(), animated: true)
            }

            if !event.hasLocation {
                return presentModalViewController()

            } else if let selectedEvent = selectedLocationState.event, event == selectedEvent {
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

    func fetchUpcomingEvents(refresh: Bool = false) {
        upcomingEvents.isInvalid = refresh
        upcomingEvents.fetch(completion: nil)
    }

    func remove(dayEvents: [Event]) throws {
        try upcomingEvents.remove(dayEvents: dayEvents)
    }

    func remove(event: Event) throws {
        try upcomingEvents.remove(event: event, commit: true)
    }

    func save(event: Event) throws {
        try upcomingEvents.save(event: event, commit: true)
    }

    func requestSetCurrent(screen: CoordinatedViewController) {
        guard let screen = screen as? UIViewController else { return }
        currentContainer = screen.parent as? UINavigationController
        currentScreen = screen
    }

    // MARK: EKEventEditViewDelegate

    func eventEditViewController(_ controller: EKEventEditViewController,
                                 didCompleteWith action: EKEventEditViewAction) {
        let eventScreen = currentScreen as! EventScreen
        var completion: (() -> Void)?
        switch action {
        case .canceled: break
        case .deleted:
            let container = currentContainer!
            container.transitioningDelegate = nil
            container.modalPresentationStyle = .fullScreen
            completion = { self.dismissViewController(animated: true) }
            try! upcomingEvents.remove(event: eventScreen.event, commit: false)
        case .saved:
            let entity = controller.event!
            eventScreen.event = Event(entity: entity)
            try! upcomingEvents.save(event: eventScreen.event, commit: false)
        }
        controller.dismiss(animated: true, completion: completion)
    }

    // MARK: MapViewControllerDelegate

    func mapViewController(_ mapViewController: MapViewController,
                           didSelectMapItem mapItem: MKMapItem) {
        selectedLocationState.mapItem = mapItem
        if let eventScreen = currentScreen as? EventScreen {
            eventScreen.updateLocation(mapItem: mapItem)
        }
        dispatchAfter(1) {
            self.dismissViewController(animated: true)
        }
    }

    func mapViewController(_ mapViewController: MapViewController,
                           didDeselectMapItem mapItem: MKMapItem) {
        if mapItem.name == selectedLocationState.mapItem?.name {
            selectedLocationState.mapItem = nil
        }
        if let eventScreen = currentScreen as? EventScreen {
            eventScreen.updateLocation(mapItem: nil)
        }
        if !mapViewController.hasResults {
            dispatchAfter(1) {
                self.dismissViewController(animated: true)
            }
        }
    }

    func resultsViewController(_ resultsViewController: SearchResultsViewController,
                               didConfigureResultViewCell cell: SearchResultsViewCell,
                               withMapItem mapItem: MKMapItem) {
        Appearance.configureSearchResult(cell: cell, table: resultsViewController.tableView)
    }

    func dismissModalMapViewController(sender: Any?) {
        dismissViewController(animated: true)
    }

}
