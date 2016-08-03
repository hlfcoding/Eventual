//
//  AccessibleViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@objc protocol AccessibleViewController {

    func setUpAccessibility(specificElement: AnyObject?)
    optional func renderAccessibilityValueForElement(element: AnyObject, value: AnyObject?)

}

extension DayViewController: AccessibleViewController {

    func setUpAccessibility(specificElement: AnyObject?) {
        switch specificElement {

        case let buttonItem as UIBarButtonItem:
            buttonItem.accessibilityLabel = a(.AddDayEvent)

        case nil:
            collectionView!.accessibilityLabel = a(.DayEvents)

        default: fatalError("Unsupported element.")
        }
    }

}

extension EventViewController: AccessibleViewController {

    func setUpAccessibility(specificElement: AnyObject?) {
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

extension MonthsViewController: AccessibleViewController {

    func setUpAccessibility(specificElement: AnyObject?) {
        switch specificElement {

        case let buttonItem as UIBarButtonItem:
            buttonItem.accessibilityLabel = a(.AddEvent)

        case nil:
            collectionView!.accessibilityLabel = a(.MonthDays)

        default: fatalError("Unsupported element.")
        }
    }

}
