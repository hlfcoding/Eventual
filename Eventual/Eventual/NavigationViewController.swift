//
//  NavigationViewController
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class NavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.applyCustomBorderColor(view.tintColor)
        delegate = AppDelegate.sharedDelegate.navigationCoordinator
    }

    // TODO: Temporary hack until fully switching to size classes.
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        var navigationViewController: UINavigationController = self
        while let presentedViewController = navigationViewController.presentedViewController as? UINavigationController {
            navigationViewController = presentedViewController
        }
        if let eventViewController = navigationViewController.topViewController as? EventViewController {
            return eventViewController.supportedInterfaceOrientations()
        }
        return super.supportedInterfaceOrientations()
    }

}
