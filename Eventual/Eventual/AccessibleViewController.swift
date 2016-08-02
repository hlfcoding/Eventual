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
        dayLabel.accessibilityHint = t("Tap to set a later date.", "day label a11y hint")
        dayMenuView.accessibilityLabel = a(.EventScreenTitle)
        dayMenuView.accessibilityHint = t("Swipe left or right to select day option.", "day menu a11y hint")
        descriptionView.accessibilityLabel = a(.EventDescription)
        saveItem.accessibilityLabel = a(.SaveEvent)
        timeDatePicker.accessibilityLabel = a(.PickTime)
        timeItem.accessibilityLabel = a(.EventTime)
        timeItem.accessibilityHint = t("Tap to toggle event time picker.", "time toolbar button a11y hint")
    }

    func renderAccessibilityValueForElement(element: AnyObject, value: AnyObject?) {
        switch (element, value) {

        case (dayLabel as UILabel, let date as NSDate?):
            guard let date = date else {
                dayLabel.accessibilityValue = nil
                break
            }
            dayLabel.accessibilityValue = NSDateFormatter.accessibleDateFormatter.stringFromDate(date)

        case (dayMenuView as UIView, nil):
            if let
                visibleItem = dayMenuView.visibleItem,
                optionLabel = DayMenuItem.fromView(visibleItem)?.labelText {
                dayMenuView.accessibilityValue = t("\(optionLabel) day option selected.", "day menu a11y value")
            } else {
                dayMenuView.accessibilityValue = nil
            }

        case (timeItem as UIBarButtonItem, let on as Bool):
            timeItem.accessibilityValue = on ? t("Event has custom time.", "time toolbar button active") : nil

        default: fatalError("Unsupported element, value.")
        }
    }

}
