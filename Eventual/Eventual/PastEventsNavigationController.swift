//
//  PastEventsNavigationController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

class PastEventsNavigationController: MonthEventNavigationController {

    override var supportedSegues: [Segue] {
        return super.supportedSegues + [.showMonth, .unwindToArchive]
    }

    override func restoreState() {
        let appDelegate = AppDelegate.sharedDelegate!
        appDelegate.flowEvents = appDelegate.pastEvents
        dataSource = appDelegate.flowEvents
        refreshEvents(nil)
    }

    override func prepareSegueForDescendant(_ sender: Any?) {
        super.prepareSegueForDescendant(sender)

        let viewController = sender as! CoordinatedViewController
        let (type, destination, source, destinationContainer, sourceContainer) =
            unpackSegue(for: viewController)

        switch (type, destination, source) {

        case (.showMonth, let monthScreen as MonthScreen, let archiveScreen as ArchiveScreen):
            destinationContainer!.modalPresentationStyle = .custom
            destinationContainer!.transitioningDelegate = archiveScreen.zoomTransitionTrait
            archiveScreen.currentSelectedMonthDate = archiveScreen.selectedMonthDate
            monthScreen.isAddingEventEnabled = dataSource! is UpcomingEvents
            monthScreen.monthDate = archiveScreen.currentSelectedMonthDate
            monthScreen.unwindSegue = .unwindToArchive

        case (.unwindToArchive, let archiveScreen as ArchiveScreen, is CoordinatedViewController):
            guard let container = sourceContainer else { break }

            if archiveScreen.isCurrentItemRemoved {
                container.transitioningDelegate = nil
                container.modalPresentationStyle = .fullScreen
            }

        default: break
        }
    }

}
