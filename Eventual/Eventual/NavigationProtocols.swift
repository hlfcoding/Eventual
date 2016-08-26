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

}

protocol CoordinatedCollectionViewController: CoordinatedViewController {

    var currentIndexPath: NSIndexPath? { get set }
    var isCurrentItemRemoved: Bool { get }
    var zoomTransitionTrait: CollectionViewZoomTransitionTrait! { get set }

}

protocol DayScreen: CoordinatedCollectionViewController {

    var currentSelectedEvent: Event? { get set }
    var dayDate: NSDate! { get set }
    var selectedEvent: Event? { get }

    func updateData(andReload reload: Bool)

}

protocol EventScreen: CoordinatedViewController {

    var event: Event! { get set }
    var unwindSegueIdentifier: String? { get set }

    func updateLocation(mapItem: MKMapItem)

}

protocol MonthsScreen: CoordinatedCollectionViewController {

    var currentSelectedDayDate: NSDate? { get set }
    var selectedDayDate: NSDate? { get }
    
}

/**
 This trigger-action minority are to supplement the storyboard's majority.
 */
enum NavigationActionTrigger {

    case BackgroundTap, LocationButtonTap
    case InteractiveTransitionBegin

}

/**
 Mostly methods to improve view-controller isolation.
 */
protocol NavigationCoordinatorProtocol: NSObjectProtocol {

    var monthsEvents: MonthsEvents? { get }

    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    func performNavigationActionForTrigger(trigger: NavigationActionTrigger,
                                           viewController: CoordinatedViewController)
    
    func removeEvent(event: Event) throws
    func saveEvent(event: Event) throws

}
