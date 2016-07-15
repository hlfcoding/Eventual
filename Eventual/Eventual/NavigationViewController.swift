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

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask { // TODO: Framework error on the return type.
        if topViewController is EventViewController {
            return .Portrait
        }
        return super.supportedInterfaceOrientations()
    }

}
