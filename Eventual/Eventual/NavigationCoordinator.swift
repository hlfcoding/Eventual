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
    case showArchive = "ShowArchive"
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

    enum Flow: String {
        case pastEvents, upcomingEvents
    }

    weak var currentContainer: UINavigationController?
    weak var currentScreen: UIViewController? {
        didSet {
            guard let currentScreen = currentScreen else { return }
            currentContainer = currentScreen.navigationController
            currentScreenRestorationIdentifier = currentScreen.restorationIdentifier
        }
    }

    var eventManager: EventManager!
    var flow: Flow = .upcomingEvents
    var hasCalendarAccess = false
    var pastEvents: PastEvents!
    var upcomingEvents: UpcomingEvents!
    var selectedLocationState: (mapItem: MKMapItem?, event: Event?) = (nil, nil)

    private var appDidBecomeActiveObserver: NSObjectProtocol!
    private var flowEvents: MonthEventDataSource {
        switch flow {
        case .pastEvents: return pastEvents
        case .upcomingEvents: return upcomingEvents
        }
    }

    init(eventManager: EventManager) {
        super.init()
        self.eventManager = eventManager
        self.pastEvents = PastEvents(manager: eventManager)
        self.upcomingEvents = UpcomingEvents(manager: eventManager)

        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidBecomeActive, object: nil, queue: nil,
            using: { _ in self.startFlow(completion: nil) }
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(appDidBecomeActiveObserver)
    }

    // MARK: Data

    func startFlow(_ flow: Flow? = nil, completion: (() -> Void)? = nil) {
        if let flow = flow {
            self.flow = flow
        }
        switch self.flow {
        case .pastEvents: self.startPastEventsFlow()
        case .upcomingEvents: self.startUpcomingEventsFlow(completion: completion)
        }
    }

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
        currentContainer!.present(viewController, animated: animated, completion: completion)
    }

    /* testable */ func dismissViewController(animated: Bool, completion: (() -> Void)? = nil) {
        currentScreen!.dismiss(animated: animated, completion: completion)
        currentScreen = currentContainer!.topViewController
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
        currentScreen = viewController
    }

    // MARK: NavigationCoordinatorProtocol

    var monthsEvents: MonthsEvents? { return flowEvents.events }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let type = Segue(rawValue: identifier) else { return }

        let destinationContainer = segue.destination as? UINavigationController
        destinationContainer?.delegate = self
        let destination = destinationContainer?.topViewController ?? segue.destination
        let sourceContainer = segue.source.navigationController

        switch (type, destination, segue.source) {

        case (.addEvent, let eventScreen as EventScreen, let source):
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

        case (.editEvent, let eventScreen as EventScreen, let dayScreen as DayScreen):
            guard let event = dayScreen.selectedEvent else { return }

            destinationContainer!.modalPresentationStyle = .custom
            destinationContainer!.transitioningDelegate = dayScreen.zoomTransitionTrait
            eventScreen.coordinator = self
            eventScreen.event = Event(entity: event.entity) // So form doesn't mutate shared state.
            eventScreen.unwindSegueIdentifier = Segue.unwindToDay.rawValue

        case (.showArchive, let archiveScreen as ArchiveScreen, is CoordinatedViewController):
            archiveScreen.coordinator = self
            startFlow(.pastEvents)

        case (.showDay, let dayScreen as DayScreen, let monthsScreen as MonthsScreen):
            destinationContainer!.modalPresentationStyle = .custom
            destinationContainer!.transitioningDelegate = monthsScreen.zoomTransitionTrait
            monthsScreen.currentSelectedDayDate = monthsScreen.selectedDayDate
            dayScreen.coordinator = self
            dayScreen.dayDate = monthsScreen.currentSelectedDayDate

        case (.unwindToDay, let dayScreen as DayScreen, is CoordinatedViewController):
            guard let container = sourceContainer else { break }

            dayScreen.currentSelectedEvent = dayScreen.selectedEvent
            if dayScreen.isCurrentItemRemoved {
                container.transitioningDelegate = nil
                container.modalPresentationStyle = .fullScreen
            }
            currentScreen = segue.destination

        case (.unwindToMonths, let monthsScreen as MonthsScreen, is CoordinatedViewController):
            guard let container = sourceContainer else { break }

            if monthsScreen.isCurrentItemRemoved {
                container.transitioningDelegate = nil
                container.modalPresentationStyle = .fullScreen
            }
            currentScreen = segue.destination

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

    var currentScreenRestorationIdentifier: String!

    var isRestoringState = false {
        didSet {
            guard isRestoringState else { return }
            startFlow() {
                assert(self.restoringScreens.count > 0)
                for (index, screen) in self.restoringScreens.enumerated() {
                    let parent: CoordinatedViewController? = (index == 0) ? nil : self.restoringScreens[index - 1]
                    self.restoreScreenState(screen, parent: parent)
                }
                self.currentScreen = self.restoringScreens.last as? UIViewController
                self.restoringScreens.removeAll()
                self.isRestoringState = false
            }
        }
    }

    private var restoringScreens = [CoordinatedViewController]()

    func pushRestoringScreen(_ screen: CoordinatedViewController) {
        restoringScreens.append(screen)
    }

    func restore(event: Event) -> Event? {
        if event.isNew {
            return Event(event: event, entity: eventManager.newEntity())
        } else if let identifier = event.decodedIdentifier,
            let entity = flowEvents.findEvent(identifier: identifier)?.entity {
            return Event(event: event, entity: entity)
        }
        return nil
    }

    func restoreScreenState(_ screen: CoordinatedViewController, parent: CoordinatedViewController?) {
        switch screen {
        case is DayScreen:
            let parent = parent as! CoordinatedCollectionViewController
            let container = (screen as! UIViewController).navigationController!
            container.modalPresentationStyle = .custom
            container.transitioningDelegate = parent.zoomTransitionTrait
        case let eventScreen as EventScreen:
            switch parent {
            case is MonthsScreen: eventScreen.unwindSegueIdentifier = Segue.unwindToMonths.rawValue
            case is DayScreen: eventScreen.unwindSegueIdentifier = Segue.unwindToDay.rawValue
            default: fatalError()
            }
        default: break
        }
        screen.finishRestoringState()
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
