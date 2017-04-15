//
//  Defines.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Error

let ErrorDomain = "ErrorDomain"

enum ErrorCode: Int {
    case Generic = 0, InvalidObject
}

// MARK: - Notifications

extension NSNotification.Name {

    static let EntityAccess = NSNotification.Name("EventualDidEntityAccess")
    static let EntityFetchOperation = NSNotification.Name("EventualDidEntityFetchOperation")
    static let EntityUpdateOperation = NSNotification.Name("EventualDidEntityUpdateOperation")

}

// MARK: - Actions

enum Action: String {

    case fetchMoreEvents = "fetchMoreEvents:"
    case prepareSegueForDescendant = "prepareSegueForDescendant:"
    case refreshEvents = "refreshEvents:"
    case restoreEvent = "restoreEvent:"
    case showEventLocation = "showEventLocation:"
    case showSystemEventEditor = "showSystemEventEditor:"

    func selector() -> Selector {
        return Selector(rawValue)
    }

    func verify(performer: UIResponder) {
        assert(performer.canPerformAction(selector(), withSender: nil))
    }

}

// MARK: - Segues

enum Segue: String {

    case addEvent = "AddEvent"
    case editEvent = "EditEvent"
    case showArchive = "ShowArchive"
    case showDay = "ShowDay"
    case showMonth = "ShowMonth"

    // MARK: Unwind Segues
    // Why have these if our IA is shallow and lacks the need to go back more than one screen?
    // Because we use a custom view as a 'back button', meaning it's a fake, since backBarButtonItem
    // can't be customized to a view.
    case unwindToArchive = "UnwindToArchive"
    case unwindToDay = "UnwindToDay"
    case unwindToMonths = "UnwindToMonths"
    
}

// MARK: - Types

typealias Attributes = [String: Any]
typealias KeyPathsMap = [String: Any]
typealias UserInfo = [String: Any]
typealias ValidationResults = [String: String]
