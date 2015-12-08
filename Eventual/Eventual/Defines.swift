//
//  Defines.swift
//  Eventual
//
//  Created by Peng Wang on 7/9/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

var sharedObserverContext = 0

// MARK: - Accessibility Labels

enum Label: String {
    case DayEvents = "Day Events"
    case EventDescription = "Event Description"
    case EventForm = "Event Form"
    case EventScreenTitle = "Event Screen Title"
    case FormatDayCell = "Day Cell At Section %d Item %d"
    case FormatDayOption = "Day Option Named %@"
    case FormatEventCell = "Event Cell At Item %d"
    case MonthDays = "Eventful Days By Month"
    case MonthsScreenTitle = "Months Screen Title"
    case NavigationBack = "Back"
    case TappableBackground = "Tappable Background"
}

// MARK: - Error

let ErrorDomain = "ErrorDomain"

enum ErrorCode: Int {
    case Generic = 0, InvalidObject
}

// MARK: - Flags

let DayUnitFlags: NSCalendarUnit = [.Day, .Month, .Year]
let HourUnitFlags: NSCalendarUnit = [.Hour, .Day, .Month, .Year]
let MonthUnitFlags: NSCalendarUnit = [.Month, .Year]

// MARK: - Keys
// NOTE: Not using enum to avoid rawValue dance.

let DatesKey = "dates"
let DaysKey = "days"
let EventsKey = "events"

let DataKey = "data"
let ErrorKey = "error"
let ResultKey = "result"
let TypeKey = "type"

// MARK: - Names

let EntityAccessDenied = "EntityAccessDenied"
let EntityAccessError = "EntityAccessError"
let EntityAccessGranted = "EntityAccessGranted"

// MARK: - Notifications

let EntityAccessNotification = "EntityAccess"
let EntitySaveOperationNotification = "EntitySaveOperation"

// MARK: - Resources

let FontName = "eventual"

enum Icon: String {
    case CheckCircle = "\u{e602}"
    case Clock = "\u{e600}"
    case Cross = "\u{e605}"
    case LeftArrow = "\u{e604}"
    case MapPin = "\u{e601}"
    case Trash = "\u{e603}"
}

enum IndicatorState: Int {
    case Normal, Active, Filled, Successful
}

// MARK: - Segues

enum Segue: String {
    case AddEvent = "SegueAddEvent"
    case EditEvent = "SegueEditEvent"
    case ShowDay = "SegueShowDay"
    // MARK: Unwind Segues
    /*
    Why have these if our IA is shallow and lacks the need to go back more than one screen?
    Because we use a custom view as a 'back button', meaning it's a fake, since backBarButtonItem
    can't be customized to a view.
    */
    case UnwindToDay = "SegueUnwindToDay"
    case UnwindToMonths = "SegueUnwindToMonths"
}

// MARK: - Protocols

protocol NavigationAppearanceDelegate: NSObjectProtocol {

    var wantsAlternateNavigationBarAppearance: Bool { get }

}

protocol NavigationTitleViewProtocol: NSObjectProtocol {

    var textColor: UIColor! { get set }

}
