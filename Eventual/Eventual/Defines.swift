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

enum ETLabel: String {
    case DayEvents = "Day Events"
    case EventScreenTitle = "Event Screen Title"
    case FormatDayCell = "Day Cell At Section %d Item %d"
    case FormatDayOption = "Day Option Named %@"
    case MonthDays = "Eventful Days By Month"
    case MonthScreenTitle = "Month Screen Title"
    case NavigationBack = "Back"
}

// MARK: - Error

let ETErrorDomain = "ETErrorDomain"

enum ETErrorCode: Int {
    case Generic = 0, InvalidObject
}

// MARK: - Resources

let ETFontName = "eventual"

enum ETIcon: String {
    case CheckCircle = "\u{e602}"
    case Clock = "\u{e600}"
    case Cross = "\u{e605}"
    case LeftArrow = "\u{e604}"
    case MapPin = "\u{e601}"
    case Trash = "\u{e603}"
}

enum ETIndicatorState: Int {
    case Normal, Active, Filled, Successful
}

// MARK: - Segues

enum ETSegue: String {
    case AddEvent = "ETSegueAddEvent"
    case EditEvent = "ETSegueEditEvent"
    case ShowDay = "ETSegueShowDay"
    case DismissToMonths = "ETSegueDismissToMonths"
}

// MARK: - Protocols

protocol NavigationAppearanceDelegate: class, NSObjectProtocol {
    
    var wantsAlternateNavigationBarAppearance: Bool { get }
    
}

protocol NavigationTitleViewProtocol: class, NSObjectProtocol {
    
    var textColor: UIColor! { get set }
    
}