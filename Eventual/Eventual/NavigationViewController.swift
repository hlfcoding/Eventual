//
//  NavigationViewController
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014-2016 Eventual App. All rights reserved.
//

import UIKit

import MapKit
import HLFMapViewController

class NavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.applyCustomBorderColor(self.view.tintColor)
        self.delegate = AppDelegate.sharedDelegate.navigationCoordinator
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask { // TODO: Framework error on the return type.
        if self.topViewController is EventViewController {
            return .Portrait
        }
        return super.supportedInterfaceOrientations()
    }

}


// MARK: - Modal View Controllers

extension NavigationViewController {

    // NOTE: This would normally be done in a storyboard, but the latter fails to auto-load the xib.
    static func modalMapViewControllerWithDelegate(delegate: MapViewControllerDelegate,
                                                   selectedMapItem: MKMapItem? = nil) -> NavigationViewController
    {
        let dismissalSelector = #selector(UIViewController.dismissViewControllerAnimated(_:completion:))
        guard delegate.respondsToSelector(dismissalSelector) else { fatalError("Needs to implement \(dismissalSelector).") }

        let mapViewController = MapViewController(nibName: "MapViewController", bundle: MapViewController.bundle)
        mapViewController.delegate = delegate
        mapViewController.selectedMapItem = selectedMapItem

        mapViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Label.NavigationBack.rawValue, style: .Plain, target: delegate, action: dismissalSelector
        )
        mapViewController.customizeNavigationItem()

        let navigationController = NavigationViewController(rootViewController: mapViewController)
        return navigationController
    }
    
}
