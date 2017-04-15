//
//  UpcomingEventsNavigationController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

class UpcomingEventsNavigationController: MonthEventNavigationController {

    override var supportedSegues: [Segue] {
        return super.supportedSegues + [.showArchive]
    }

    override func prepareSegueForDescendant(_ sender: Any?) {
        super.prepareSegueForDescendant(sender)

        let viewController = sender as! CoordinatedViewController
        let (type, destination, source, destinationContainer, _) = unpackSegue(for: viewController)
        let appDelegate = AppDelegate.sharedDelegate!

        switch (type, destination, source) {

        case (.showArchive, let archiveScreen as ArchiveScreen, is CoordinatedViewController):
            archiveScreen.unwindSegue = .unwindToMonths
            appDelegate.flowEvents = appDelegate.pastEvents
            let navigationController = destinationContainer as! PastEventsNavigationController
            navigationController.dataSource = appDelegate.flowEvents

        case (.unwindToMonths, is MonthsScreen, is ArchiveScreen):
            appDelegate.flowEvents = appDelegate.upcomingEvents
            dataSource = appDelegate.flowEvents

        default: break
        }
    }

}
