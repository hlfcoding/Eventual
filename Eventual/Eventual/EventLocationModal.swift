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

        let closeItem = UIBarButtonItem()
        closeItem.setTitleTextAttributes([ NSFontAttributeName: Appearance.iconBarButtonItemFont ], for: .normal)
        closeItem.accessibilityLabel = a(.navigationBack)
        closeItem.title = Icon.cross.rawValue

        closeItem.action = dismissalSelector
        closeItem.target = delegate
        mapViewController.navigationItem.leftBarButtonItem = closeItem

        let navigationController = UINavigationController(navigationBarClass: NavigationBar.self, toolbarClass: nil)
        navigationController.pushViewController(mapViewController, animated: false)
        return navigationController
    }

}
