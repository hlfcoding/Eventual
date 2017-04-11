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
    weak var currentSegue: UIStoryboardSegue? { get set }
    var unwindSegue: Segue? { get set }
    var view: UIView! { get set }

    func finishRestoringState()

}

protocol CoordinatedCollectionViewController: CoordinatedViewController {

    var currentIndexPath: IndexPath? { get set }
    var isAddingEventEnabled: Bool { get set }
    var isCurrentItemRemoved: Bool { get }
    var zoomTransitionTrait: CollectionViewZoomTransitionTrait! { get set }

}

protocol ArchiveScreen: CoordinatedCollectionViewController {

    var currentSelectedMonthDate: Date? { get set }
    var selectedMonthDate: Date? { get }

}

protocol DayScreen: CoordinatedCollectionViewController {

    var currentSelectedEvent: Event? { get set }
    var dayDate: Date! { get set }
    var monthDate: Date! { get set }
    var selectedEvent: Event? { get }

}

protocol EventScreen: CoordinatedViewController {

    var event: Event! { get set }
    var unwindSegueIdentifier: String? { get set }

    func updateLocation(mapItem: MKMapItem?)

}

protocol MonthScreen: CoordinatedCollectionViewController {

    var currentSelectedDayDate: Date? { get set }
    var monthDate: Date! { get set }
    var selectedDayDate: Date? { get }

}

protocol MonthsScreen: CoordinatedCollectionViewController {

    var currentSelectedDayDate: Date? { get set }
    var currentSelectedMonthDate: Date? { get set }
    var selectedDayDate: Date? { get }
    var selectedMonthDate: Date? { get }

}

/**
 Mostly methods to improve view-controller isolation.
 */
protocol NavigationCoordinatorProtocol: NSObjectProtocol {

    var monthsEvents: MonthsEvents? { get }

    func presentingViewController(of viewController: CoordinatedViewController) -> CoordinatedViewController?

    func fetchPastEvents(refresh: Bool)
    func fetchUpcomingEvents(refresh: Bool)
    func remove(dayEvents: [Event]) throws
    func remove(event: Event) throws
    func save(event: Event) throws

    // MARK: UIStateRestoring

    var isRestoringState: Bool { get set }

    func pushRestoringScreen(_ screen: CoordinatedViewController)
    func restore(event: Event) -> Event?

}
