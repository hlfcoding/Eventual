//
//  NavigationProtocols.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

import MapKit

/**
 Also known as a 'screen'.
 */
protocol CoordinatedViewController: NSObjectProtocol {

    weak var coordinator: NavigationCoordinatorProtocol? { get set }
    var view: UIView! { get set }

    func finishRestoringState()

}

protocol CoordinatedCollectionViewController: CoordinatedViewController {

    var currentIndexPath: IndexPath? { get set }
    var isCurrentItemRemoved: Bool { get }
    var zoomTransitionTrait: CollectionViewZoomTransitionTrait! { get set }

}

protocol DayScreen: CoordinatedCollectionViewController {

    var currentSelectedEvent: Event? { get set }
    var dayDate: Date! { get set }
    var selectedEvent: Event? { get }

}

protocol EventScreen: CoordinatedViewController {

    var event: Event! { get set }
    var unwindSegueIdentifier: String? { get set }

    func updateLocation(mapItem: MKMapItem?)

}

protocol MonthsScreen: CoordinatedCollectionViewController {

    var currentSelectedDayDate: Date? { get set }
    var currentSelectedMonthDate: Date? { get set }
    var selectedDayDate: Date? { get }
    
}

/**
 This trigger-action minority are to supplement the storyboard's majority.
 */
enum NavigationActionTrigger {

    case backgroundTap, editInCalendarAppTap, locationButtonTap, manualDismissal

}

/**
 Mostly methods to improve view-controller isolation.
 */
protocol NavigationCoordinatorProtocol: NSObjectProtocol {

    var monthsEvents: MonthsEvents? { get }
    var isRestoringState: Bool { get set }

    func prepare(for segue: UIStoryboardSegue, sender: Any?)
    func performNavigationAction(for trigger: NavigationActionTrigger,
                                 viewController: CoordinatedViewController)

    func fetchUpcomingEvents(refresh: Bool)
    func remove(dayEvents: [Event]) throws
    func remove(event: Event) throws
    func save(event: Event) throws

    func requestSetCurrent(screen: CoordinatedViewController)

}
