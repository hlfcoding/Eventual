//
//  NavigationController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

import MapKit
import HLFMapViewController

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.applyCustomBorderColor(self.view.tintColor)
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask { // TODO: Framework error on the return type.
        if self.topViewController is EventViewController {
            return .Portrait
        }
        return super.supportedInterfaceOrientations()
    }

}


// MARK: - Modal View Controllers

extension NavigationController {

    // NOTE: This would normally be done in a storyboard, but the latter fails to auto-load the xib.
    static func modalMapViewControllerWithDelegate(delegate: MapViewControllerDelegate,
                                                   selectedMapItem: MKMapItem? = nil) -> NavigationController
    {
        guard delegate.respondsToSelector(Selector("dismissModalMapViewController:"))
              else { fatalError("Needs to implement dismissModalMapViewController:.") }

        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.delegate = delegate
        mapViewController.selectedMapItem = selectedMapItem

        mapViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Label.NavigationBack.rawValue, style: .Plain,
            target: delegate, action: "dismissModalMapViewController:"
        )
        mapViewController.customizeNavigationItem()

        let navigationController = NavigationController(rootViewController: mapViewController)
        return navigationController
    }
    
}
