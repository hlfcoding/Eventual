//
//  EventLocationModal.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

import MapKit
import HLFMapViewController

extension MapViewController {

    /**
     This would normally be done in a storyboard, but the latter fails to auto-load the xib.
     */
    static func modalMapViewControllerWithDelegate(delegate: MapViewControllerDelegate,
                                                   selectedMapItem: MKMapItem? = nil) -> UINavigationController {
        let dismissalSelector = #selector(NavigationCoordinator.dismissModalMapViewController(_:))
        guard delegate.respondsToSelector(dismissalSelector) else { preconditionFailure("Needs to implement \(dismissalSelector).") }

        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.delegate = delegate
        mapViewController.selectedMapItem = selectedMapItem

        mapViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: a(.NavigationBack), style: .Plain, target: delegate, action: dismissalSelector
        )
        mapViewController.customizeNavigationItem()

        let navigationController = UINavigationController(navigationBarClass: NavigationBar.self, toolbarClass: nil)
        navigationController.pushViewController(mapViewController, animated: false)
        return navigationController
    }

}
