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
        let (type, destination, source, _, _) = unpackSegue(for: viewController)

        switch (type, destination, source) {

        case (.showArchive, let archiveScreen as ArchiveScreen, is CoordinatedViewController):
            (archiveScreen.coordinator as! NavigationCoordinator).startFlow(.pastEvents)

        default: break
        }

    }
    
}
