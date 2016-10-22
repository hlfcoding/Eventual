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
    static func modalMapViewController(delegate: MapViewControllerDelegate,
                                       selectedMapItem: MKMapItem? = nil) -> UINavigationController {
        let dismissalSelector = #selector(NavigationCoordinator.dismissModalMapViewController(sender:))
        guard delegate.responds(to: dismissalSelector) else { preconditionFailure("Needs to implement \(dismissalSelector).") }

        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.delegate = delegate
        mapViewController.selectedMapItem = selectedMapItem

        let backItem = BackButtonItem()
        backItem.target = delegate; backItem.action = dismissalSelector
        mapViewController.navigationItem.leftBarButtonItem = backItem

        let navigationController = UINavigationController(navigationBarClass: NavigationBar.self, toolbarClass: nil)
        navigationController.pushViewController(mapViewController, animated: false)
        return navigationController
    }

}
