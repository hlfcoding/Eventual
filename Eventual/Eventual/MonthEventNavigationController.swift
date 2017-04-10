//
//  MonthEventNavigationController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

class MonthEventNavigationController: FlowNavigationController {

    override var supportedSegues: [Segue] {
        return [.showDay]
    }

    override func prepareSegue(_ sender: Any?) {
        super.prepareSegue(sender)

        let viewController = sender as! CoordinatedViewController
        let (type, destination, source, destinationContainer, _) = unpackSegue(for: viewController)

        switch (type, destination, source) {

        case (.showDay, let dayScreen as DayScreen, let sourceScreen as CoordinatedCollectionViewController):
            dayScreen.isAddingEventEnabled = dataSource! is UpcomingEvents
            destinationContainer!.modalPresentationStyle = .custom
            destinationContainer!.transitioningDelegate = sourceScreen.zoomTransitionTrait
            switch sourceScreen {

            case let monthsScreen as MonthsScreen:
                monthsScreen.currentSelectedDayDate = monthsScreen.selectedDayDate
                monthsScreen.currentSelectedMonthDate = monthsScreen.selectedMonthDate
                dayScreen.dayDate = monthsScreen.currentSelectedDayDate
                dayScreen.monthDate = monthsScreen.currentSelectedMonthDate

            case let monthScreen as MonthScreen:
                monthScreen.currentSelectedDayDate = monthScreen.selectedDayDate
                dayScreen.dayDate = monthScreen.currentSelectedDayDate
                dayScreen.monthDate = monthScreen.monthDate

            default: fatalError()
            }

        default: fatalError()
        }
    }

}

class PastEventsNavigationController: MonthEventNavigationController {}

class UpcomingEventsNavigationController: MonthEventNavigationController {}
