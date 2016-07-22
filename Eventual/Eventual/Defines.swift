//
//  Defines.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

// MARK: - Accessibility Labels

enum Label: String {
    case AddDayEvent = "Add Event To Day"
    case AddEvent = "Add Event"
    case DayEvents = "Day Events"
    case EventDate = "Event Date"
    case EventDescription = "Event Description"
    case EventForm = "Event Form"
    case EventScreenTitle = "Event Screen Title"
    case FormatDayCell = "Day Cell At Section %d Item %d"
    case FormatDayOption = "Day Option Named %@"
    case FormatEventCell = "Event Cell At Item %d"
    case MonthDays = "Eventful Days By Month"
    case MonthsScreenTitle = "Months Screen Title"
    case NavigationBack = "Back"
    case PickDate = "Pick Date"
    case SaveEvent = "Save Event"
    case TappableBackground = "Tappable Background"
}

// MARK: - Error

let ErrorDomain = "ErrorDomain"

enum ErrorCode: Int {
    case Generic = 0, InvalidObject
}

// MARK: - Notifications

let EntityDeletionAction = "DoEntityDeletion"

let EntityAccessNotification = "DidEntityAccess"
let EntityUpdateOperationNotification = "DidEntityUpdateOperation"

// MARK: - Types

typealias Attributes = [String: AnyObject]
typealias KeyPathsMap = [String: AnyObject]
typealias UserInfo = [String: AnyObject]
typealias ValidationResults = [String: String]
