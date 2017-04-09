//
//  NavigationCoordinator.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

// MARK: Segues & Actions

enum Segue: String {

    case addEvent = "AddEvent"
    case editEvent = "EditEvent"
    case showArchive = "ShowArchive"
    case showDay = "ShowDay"
    case showMonth = "ShowMonth"

    // MARK: Unwind Segues
    // Why have these if our IA is shallow and lacks the need to go back more than one screen?
    // Because we use a custom view as a 'back button', meaning it's a fake, since backBarButtonItem
    // can't be customized to a view.
    case unwindToArchive = "UnwindToArchive"
    case unwindToDay = "UnwindToDay"
    case unwindToMonths = "UnwindToMonths"

}

/**
 Loose interpretation of [coordinators](http://khanlou.com/2015/10/coordinators-redux/) to contain
 flow logic. It explicitly attaches itself to `CoordinatedViewController`s and `UINavigationController`s
 during segue preparation, but should be manually attached during initialization or manual presenting
 of external view-controllers. Unlike the article, a tree of coordinators is overkill for us.
 */
final class NavigationCoordinator: NSObject, NavigationCoordinatorProtocol, UINavigationControllerDelegate {

    // MARK: State

    enum Flow: String {
        case pastEvents, upcomingEvents
    }

    weak var currentScreen: UIViewController? {
        didSet {
            guard let currentScreen = currentScreen else { return }
            currentScreenRestorationIdentifier = currentScreen.restorationIdentifier
        }
    }

    var eventManager: EventManager!
    var flow: Flow = .upcomingEvents
    var pastEvents: PastEvents!
    var upcomingEvents: UpcomingEvents!

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
        pastEvents = PastEvents(manager: eventManager)
        upcomingEvents = UpcomingEvents(manager: eventManager)

        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidBecomeActive, object: nil, queue: nil,
            using: { _ in self.startFlow() }
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(appDidBecomeActiveObserver)
    }

    // MARK: Data

    func startFlow(_ flow: Flow? = nil, completion: (() -> Void)? = nil) {
        guard eventManager.hasAccess else {
            let center = NotificationCenter.default
            var observer: NSObjectProtocol?
            observer = center.addObserver(forName: .EntityAccess, object: nil, queue: nil) {
                guard let observer = observer,
                    let payload = $0.userInfo?.notificationUserInfoPayload() as? EntityAccessPayload,
                    payload.result == .granted
                    else { return }
                NotificationCenter.default.removeObserver(observer)
                self.startFlow(flow, completion: completion)
            }
            eventManager.requestAccess()
            return
        }
        if let flow = flow {
            self.flow = flow
        }
        switch self.flow {
        case .pastEvents:
            pastEvents.isInvalid = true
            pastEvents.fetch(completion: completion)
        case .upcomingEvents:
            upcomingEvents.fetch(completion: completion)
        }
    }

    // MARK: Helpers

    private func segue(trigger: NavigationActionTrigger,
                       viewController: CoordinatedViewController) -> Segue? {
        switch (trigger, viewController, flow) {
        case (.backgroundTap, is DayScreen, .upcomingEvents),
             (.backgroundTap, is MonthsScreen, .upcomingEvents):
            return .addEvent
        case (.manualDismissal, is ArchiveScreen, .pastEvents),
             (.manualDismissal, is DayScreen, _):
            return .unwindToMonths
        case (.manualDismissal, is MonthScreen, .pastEvents):
            return .unwindToArchive
        case (.manualDismissal, let eventScreen as EventScreen, _):
            return Segue(rawValue: eventScreen.unwindSegueIdentifier!)
        default: return nil
        }
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        guard !isRestoringState else { return }
        currentScreen = viewController
    }

    // MARK: NavigationCoordinatorProtocol

    var monthsEvents: MonthsEvents? { return flowEvents.events }

    func presentingViewController(of viewController: CoordinatedViewController) -> CoordinatedViewController? {
        return ((viewController as? UIViewController)?
            .presentingViewController as? UINavigationController)?
            .topViewController as? CoordinatedViewController
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let type = Segue(rawValue: identifier) else { return }

        if var container = segue.destination as? FlowController {
            container.dataSource = flowEvents
        }

        let destinationContainer = segue.destination as? UINavigationController
        if !(destinationContainer is EventNavigationController) {
            destinationContainer?.delegate = self
        }
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

        case (.showDay, let dayScreen as DayScreen, let sourceScreen as CoordinatedCollectionViewController):
            destinationContainer!.modalPresentationStyle = .custom
            destinationContainer!.transitioningDelegate = sourceScreen.zoomTransitionTrait
            switch sourceScreen {
            case let monthsScreen as MonthsScreen:
                monthsScreen.currentSelectedDayDate = monthsScreen.selectedDayDate
                monthsScreen.currentSelectedMonthDate = monthsScreen.selectedMonthDate
                dayScreen.dayDate = monthsScreen.currentSelectedDayDate
                dayScreen.monthDate = monthsScreen.currentSelectedMonthDate
            case let monthScreen as MonthScreen:
                monthScreen.currentSelectedDayDate = monthScreen.selectedDayDate
                dayScreen.dayDate = monthScreen.currentSelectedDayDate
                dayScreen.monthDate = monthScreen.monthDate
            default: fatalError()
            }
            dayScreen.coordinator = self
            dayScreen.isAddingEventEnabled = flow == .upcomingEvents

        case (.showMonth, let monthScreen as MonthScreen, let archiveScreen as ArchiveScreen):
            destinationContainer!.modalPresentationStyle = .custom
            destinationContainer!.transitioningDelegate = archiveScreen.zoomTransitionTrait
            archiveScreen.currentSelectedMonthDate = archiveScreen.selectedMonthDate
            monthScreen.coordinator = self
            monthScreen.isAddingEventEnabled = flow == .upcomingEvents
            monthScreen.monthDate = archiveScreen.currentSelectedMonthDate

        case (.unwindToArchive, let archiveScreen as ArchiveScreen, is CoordinatedViewController):
            guard let container = sourceContainer else { break }

            if archiveScreen.isCurrentItemRemoved {
                container.transitioningDelegate = nil
                container.modalPresentationStyle = .fullScreen
            }
            currentScreen = segue.destination

        case (.unwindToDay, let dayScreen as DayScreen, _):
            guard let container = sourceContainer else { break }

            dayScreen.currentSelectedEvent = dayScreen.selectedEvent
            if dayScreen.isCurrentItemRemoved {
                container.transitioningDelegate = nil
                container.modalPresentationStyle = .fullScreen
            }
            currentScreen = segue.destination

        case (.unwindToMonths, let destinationScreen as CoordinatedCollectionViewController, _):
            guard let container = sourceContainer else { break }

            if destinationScreen is MonthsScreen && flow != .upcomingEvents {
                flow = .upcomingEvents
                if flowEvents.events == nil {
                    startFlow()
                }
            }
            if destinationScreen.isCurrentItemRemoved {
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
        if let segue = segue(trigger: trigger, viewController: viewController) {
            if performer.shouldPerformSegue(withIdentifier: segue.rawValue, sender: self) {
                performer.performSegue(withIdentifier: segue.rawValue, sender: self)
            }
        }
    }

    func fetchPastEvents(refresh: Bool = false) {
        pastEvents.isInvalid = refresh
        pastEvents.fetch(completion: nil)
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
            let flow: Flow = (restoringScreens[1] is ArchiveScreen) ? .pastEvents : .upcomingEvents
            startFlow(flow) {
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
}
