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
    case EventScreenTitle = "Event Screen Title"
    case FormatDayCell = "Day Cell At Section %d Item %d"
    case FormatDayOption = "Day Option Named %@"
    case MonthDays = "Eventful Days By Month"
    case MonthScreenTitle = "Month Screen Title"
    case NavigationBack = "Back"
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
    case DismissToMonths = "SegueDismissToMonths"
}

// MARK: - Protocols

protocol NavigationAppearanceDelegate: NSObjectProtocol {
    
    var wantsAlternateNavigationBarAppearance: Bool { get }
    
}

protocol NavigationTitleViewProtocol: NSObjectProtocol {
    
    var textColor: UIColor! { get set }
    
}