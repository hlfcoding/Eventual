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
        let font = UIFont(name: Appearance.fontName, size: Appearance.iconBarButtonItemFontSize - 3)!
        closeItem.setTitleTextAttributes([ NSFontAttributeName: font ], for: .normal)
        closeItem.accessibilityLabel = a(.navigationBack)
        closeItem.title = Icon.cross.rawValue

        closeItem.action = dismissalSelector
        closeItem.target = delegate
        mapViewController.navigationItem.leftBarButtonItem = closeItem

        return UINavigationController(rootViewController: mapViewController)
    }

}
