//
//  AppTabBarController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

final class AppTabBarController: TabBarController {

    override var selectedIndex: Int {
        willSet {
            let appDelegate = AppDelegate.shared!
            switch viewControllers![newValue] {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Appearance.lightGrayColor
    }

}
