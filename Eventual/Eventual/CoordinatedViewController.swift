//
//  CoordinatedViewController.swift
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

    weak var currentSegue: UIStoryboardSegue? { get set }
    var unwindSegue: Segue? { get set }
    var view: UIView! { get set }

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
