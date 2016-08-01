//
//  AccessibleViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol AccessibleViewController {

    func setUpAccessibility()
    func renderAccessibilityValueForElement(element: AnyObject, value: AnyObject?)

}

extension EventViewController: AccessibleViewController {

    func setUpAccessibility() {
        dayDatePicker.accessibilityLabel = a(.PickDate)
        dayLabel.accessibilityLabel = a(.EventDate)
        dayLabel.accessibilityHint = t("Tap to set a later date.", "day label hint")
        dayMenuView.accessibilityLabel = a(.EventScreenTitle)
        descriptionView.accessibilityLabel = a(.EventDescription)
        saveItem.accessibilityLabel = a(.SaveEvent)
        timeDatePicker.accessibilityLabel = a(.PickTime)
        timeItem.accessibilityLabel = a(.EventTime)
        timeItem.accessibilityHint = t("Tap to toggle event time picker.", "time toolbar button hint")
    }

    func renderAccessibilityValueForElement(element: AnyObject, value: AnyObject?) {
        switch (element, value) {

        case (dayLabel as UILabel, let date as NSDate?):
            guard let date = date else {
                dayLabel.accessibilityValue = nil
                break
            }
            dayLabel.accessibilityValue = NSDateFormatter.accessibleDateFormatter.stringFromDate(date)

        case (timeItem as UIBarButtonItem, let on as Bool):
            timeItem.accessibilityValue = on ? t("Event has custom time.") : nil

        default: fatalError("Unsupported element, value.")
        }
    }

}
