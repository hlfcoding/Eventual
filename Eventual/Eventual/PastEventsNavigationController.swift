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
        return super.supportedSegues + [.showMonth]
    }

    override func prepareSegue(_ sender: Any?) {
        super.prepareSegue(sender)

        let viewController = sender as! CoordinatedViewController
        let (type, destination, source, destinationContainer, _) = unpackSegue(for: viewController)

        switch (type, destination, source) {

        case (.showMonth, let monthScreen as MonthScreen, let archiveScreen as ArchiveScreen):
            destinationContainer!.modalPresentationStyle = .custom
            destinationContainer!.transitioningDelegate = archiveScreen.zoomTransitionTrait
            archiveScreen.currentSelectedMonthDate = archiveScreen.selectedMonthDate
            monthScreen.isAddingEventEnabled = dataSource! is UpcomingEvents
            monthScreen.monthDate = archiveScreen.currentSelectedMonthDate

        default: break
        }
    }

}
