//
//  ETDefines.swift
//  Eventual
//
//  Created by Peng Wang on 7/9/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import Foundation

// MARK: Accessibility Labels

enum ETLabel: String {
    case DayEvents = "Day Events"
    case EventScreenTitle = "Event Screen Title"
    case FormatDayCell = "Day Cell At Section %d Item %d"
    case FormatDayOption = "Day Option Named %@"
    case MonthDays = "Eventful Days By Month"
    case MonthScreenTitle = "Month Screen Title"
    case NavigationBack = "Back"
}

// MARK: Error

let ETErrorDomain = "ETErrorDomain"

enum ETErrorCode: Int {
    case Generic = 0, InvalidObject
}

// MARK: Segues

enum ETSegue: String {
    case AddDay = "ETSegueAddDay"
    case ShowDay = "ETSegueShowDay"
    case DismissToMonths = "ETSegueDismissToMonths"
}