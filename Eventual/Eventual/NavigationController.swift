//
//  NavigationController
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.applyCustomBorderColor(view.tintColor)
        delegate = AppDelegate.sharedDelegate.navigationCoordinator
    }

    // TODO: Temporary hack until fully switching to size classes.
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        var navigationController: UINavigationController = self
        while let presentedViewController = navigationController.presentedViewController as? UINavigationController {
            navigationController = presentedViewController
        }
        if let eventViewController = navigationController.topViewController as? EventViewController {
            return eventViewController.supportedInterfaceOrientations()
        }
        return super.supportedInterfaceOrientations()
    }

}
