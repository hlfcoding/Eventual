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
        return [.addEvent, .editEvent, .showDay]
    }

    override func prepareSegue(_ sender: Any?) {
        super.prepareSegue(sender)

        let viewController = sender as! CoordinatedViewController
        let (type, destination, source, destinationContainer, _) = unpackSegue(for: viewController)

        switch (type, destination, source) {

        case (.addEvent, let eventScreen as EventScreen, let sourceScreen as CoordinatedCollectionViewController):
            eventScreen.event = dataSource!.manager.newEvent()
            switch sourceScreen {

            case let dayScreen as DayScreen:
                eventScreen.event.start(date: dayScreen.dayDate)
                eventScreen.unwindSegueIdentifier = Segue.unwindToDay.rawValue
                dayScreen.currentIndexPath = nil

            case let monthsScreen as MonthsScreen:
                eventScreen.event.start(date: monthsScreen.currentSelectedMonthDate)
                eventScreen.unwindSegueIdentifier = Segue.unwindToMonths.rawValue
                monthsScreen.currentIndexPath = nil

            default: fatalError()
            }

        case (.editEvent, let eventScreen as EventScreen, let dayScreen as DayScreen):
            guard let event = dayScreen.selectedEvent else { return }

            destinationContainer!.modalPresentationStyle = .custom
            destinationContainer!.transitioningDelegate = dayScreen.zoomTransitionTrait
            eventScreen.event = Event(entity: event.entity) // So form doesn't mutate shared state.
            eventScreen.unwindSegueIdentifier = Segue.unwindToDay.rawValue

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

        default: break
        }
    }

}
