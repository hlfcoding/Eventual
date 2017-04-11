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
final class NavigationCoordinator: NSObject, NavigationCoordinatorProtocol {

    // MARK: State

    enum Flow: String {
        case pastEvents, upcomingEvents
    }

    var eventManager: EventManager!
    var flow: Flow = .upcomingEvents
    var pastEvents: PastEvents!
    var upcomingEvents: UpcomingEvents!

    private var appDidBecomeActiveObserver: NSObjectProtocol!
    var flowEvents: MonthEventDataSource {
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

    // MARK: NavigationCoordinatorProtocol

    var monthsEvents: MonthsEvents? { return flowEvents.events }

    func presentingViewController(of viewController: CoordinatedViewController) -> CoordinatedViewController? {
        return ((viewController as? UIViewController)?
            .presentingViewController as? UINavigationController)?
            .topViewController as? CoordinatedViewController
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

    var currentScreenRestorationIdentifier: String! {
        let rootViewController = UIApplication.shared.keyWindow!.rootViewController!
        return UIViewController.topViewController(from: rootViewController).restorationIdentifier!
    }

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
