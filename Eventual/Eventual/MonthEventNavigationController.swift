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
        return [.addEvent, .editEvent, .showDay, .unwindToDay, .unwindToMonths]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Action.fetchMoreEvents.verify(performer: self)
        Action.refreshEvents.verify(performer: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        let alertController = UIAlertController(
            title: t("Oh no!", "error"),
            message: t("Your device is running out of memory. We're clearing some up.", "error"),
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: t("OK", "button"), style: .default)
            { _ in alertController.dismiss(animated: true) }
        )
        present(alertController, animated: true)

        refreshEvents(nil)
    }

    // MARK: - Actions

    override func prepareSegueForDescendant(_ sender: Any?) {
        super.prepareSegueForDescendant(sender)

        let viewController = sender as! CoordinatedViewController
        let (type, destination, source, destinationContainer, sourceContainer) =
            unpackSegue(for: viewController)

        switch (type, destination, source) {

        case (.addEvent, let eventScreen as EventScreen, let sourceScreen as CoordinatedCollectionViewController):
            eventScreen.event = dataSource!.manager.newEvent()
            switch sourceScreen {

            case let dayScreen as DayScreen:
                eventScreen.event.start(date: dayScreen.dayDate)
                eventScreen.unwindSegue = .unwindToDay
                dayScreen.currentIndexPath = nil

            case let monthsScreen as MonthsScreen:
                eventScreen.event.start(date: monthsScreen.currentSelectedMonthDate)
                eventScreen.unwindSegue = .unwindToMonths
                monthsScreen.currentIndexPath = nil

            default: fatalError()
            }

        case (.editEvent, let eventScreen as EventScreen, let dayScreen as DayScreen):
            guard let event = dayScreen.selectedEvent else { break }

            destinationContainer!.modalPresentationStyle = .custom
            destinationContainer!.transitioningDelegate = dayScreen.zoomTransitionTrait
            eventScreen.event = Event(entity: event.entity) // So form doesn't mutate shared state.
            eventScreen.unwindSegue = .unwindToDay

        case (.showDay, let dayScreen as DayScreen, let sourceScreen as CoordinatedCollectionViewController):
            dayScreen.isAddingEventEnabled = dataSource! is UpcomingEvents
            dayScreen.unwindSegue = .unwindToMonths
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

        case (.unwindToDay, let dayScreen as DayScreen, _):
            guard let container = sourceContainer else { break }

            dayScreen.currentSelectedEvent = dayScreen.selectedEvent
            if dayScreen.isCurrentItemRemoved {
                container.transitioningDelegate = nil
                container.modalPresentationStyle = .fullScreen
            }

        case (.unwindToMonths, let destinationScreen as CoordinatedCollectionViewController, _):
            guard let container = sourceContainer else { break }

            if destinationScreen.isCurrentItemRemoved {
                container.transitioningDelegate = nil
                container.modalPresentationStyle = .fullScreen
            }

        default: break
        }
    }

    func fetchMoreEvents(_ sender: Any?) {
        let dataSource = self.dataSource!
        dataSource.manager.requestAccess() {
            dataSource.fetch()
        }
    }

    func refreshEvents(_ sender: Any?) {
        let dataSource = self.dataSource!
        dataSource.manager.requestAccess() {
            dataSource.isInvalid = true
            dataSource.fetch()
        }
    }

}
