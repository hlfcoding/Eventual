//
//  AppTabBarController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class AppTabBarController: TabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
    }

    override func prepareTabTransition(for viewController: UIViewController) {
        super.prepareTabTransition(for: viewController)

        let appDelegate = AppDelegate.shared!
        switch viewController {
        case let navigationController as PastEventsNavigationController:
            appDelegate.flowEvents = appDelegate.pastEvents
            navigationController.dataSource = appDelegate.flowEvents
        case let navigationController as UpcomingEventsNavigationController:
            appDelegate.flowEvents = appDelegate.upcomingEvents
            navigationController.dataSource = appDelegate.flowEvents
        default: break
        }
    }

}
