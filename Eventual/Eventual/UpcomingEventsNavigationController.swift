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

    override func prepareSegue(_ sender: Any?) {
        super.prepareSegue(sender)

        let viewController = sender as! CoordinatedViewController
        let (type, destination, source, destinationContainer, _) = unpackSegue(for: viewController)
        let appDelegate = AppDelegate.sharedDelegate!

        switch (type, destination, source) {

        case (.showArchive, let archiveScreen as ArchiveScreen, is CoordinatedViewController):
            archiveScreen.unwindSegue = .unwindToMonths
            let navigationController = destinationContainer as! PastEventsNavigationController
            navigationController.dataSource = appDelegate.pastEvents
            appDelegate.flowEvents = appDelegate.pastEvents

        case (.unwindToMonths, is MonthsScreen, is ArchiveScreen):
            appDelegate.flowEvents = appDelegate.upcomingEvents

        default: break
        }
    }

}
