//
//  NavigationCoordinator.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

import EventKit
import MapKit

// MARK: Contracts

/**
 Also known as a 'screen'.
 */
protocol CoordinatedViewController: NSObjectProtocol {

    weak var coordinator: NavigationCoordinatorProtocol! { get set }

}

/**
 This trigger-action minority are to supplement the storyboard's majority.
 */
enum NavigationActionTrigger {

    case BackgroundTap
    case InteractiveTransitionBegin

}

/**
 Mostly methods to improve view-controller isolation.
 */
protocol NavigationCoordinatorProtocol: NSObjectProtocol {

    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    func performNavigationActionForTrigger(trigger: NavigationActionTrigger,
                                           viewController: CoordinatedViewController)

}

// MARK: -

/**
 Loose interpretation of [coordinators](http://khanlou.com/2015/10/coordinators-redux/).
 It hooks into all `NavigationViewController` which then allows it to be delegated navigation from
 view controllers. Unlike the article, a tree of coordinators is overkill for this app.
 */
class NavigationCoordinator: NSObject, NavigationCoordinatorProtocol, UINavigationControllerDelegate {

    private var eventManager: EventManager { return EventManager.defaultManager }

    // MARK: Segue

    enum Segue: String {

        case AddEvent, EditEvent, ShowDay

        // MARK: Unwind Segues
        // Why have these if our IA is shallow and lacks the need to go back more than one screen?
        // Because we use a custom view as a 'back button', meaning it's a fake, since backBarButtonItem
        // can't be customized to a view.
        case UnwindToDay, UnwindToMonths

        static func fromActionTrigger(trigger: NavigationActionTrigger,
                                      viewController: CoordinatedViewController) -> Segue? {
            switch (trigger, viewController) {
            case (.BackgroundTap, is DayScreen),
                 (.BackgroundTap, is MonthsScreen): return .AddEvent
            case (.InteractiveTransitionBegin, is DayScreen): return .EditEvent
            case (.InteractiveTransitionBegin, is MonthsScreen): return .ShowDay
            default: fatalError("Unsupported trigger view-controller pair.")
            }
        }
        
    }

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
                let event = Event(entity: EKEvent(eventStore: eventManager.store))
                event.start(dayScreen.dayDate)
                eventScreen.event = event
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

            container.transitioningDelegate = dayScreen.zoomTransitionTrait
            container.modalPresentationStyle = .Custom
            // So form doesn't mutate shared state.
            eventScreen.event = Event(entity: event.entity)
            eventScreen.unwindSegueIdentifier = Segue.UnwindToDay.rawValue
            if sender is EventViewCell {
                dayScreen.zoomTransitionTrait.isInteractive = false
            }

        case .ShowDay:
            guard let
                container = segue.destinationViewController as? NavigationViewController,
                dayScreen = container.topViewController as? DayScreen,
                monthsScreen = segue.sourceViewController as? MonthsScreen
                else { break }
            
            container.modalPresentationStyle = .Custom
            container.transitioningDelegate = monthsScreen.zoomTransitionTrait
            monthsScreen.currentSelectedDayDate = monthsScreen.selectedDayDate
            dayScreen.dayDate = monthsScreen.currentSelectedDayDate
            if sender is DayViewCell {
                monthsScreen.zoomTransitionTrait.isInteractive = false
            }

        case .UnwindToDay: break
        case .UnwindToMonths: break

        }
    }

    func performNavigationActionForTrigger(trigger: NavigationActionTrigger,
                                           viewController: CoordinatedViewController) {
        guard let performer = viewController as? UIViewController else { return }
        let segue = Segue.fromNavigationActionTrigger(trigger, viewController: viewController)
        performer.performSegueWithIdentifier(segue.rawValue, sender: self)
    }

}
