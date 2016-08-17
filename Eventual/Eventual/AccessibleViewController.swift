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
        switch specificElement {

        case drawerView as EventDatePickerDrawerView:
            dayDatePicker.accessibilityLabel = a(.PickDate)
            timeDatePicker.accessibilityLabel = a(.PickTime)

        default:
            dayLabel.accessibilityLabel = a(.EventDate)
            dayLabel.accessibilityHint = t("Tap to set a later date.", "day label a11y hint")
            dayMenuView.accessibilityLabel = a(.EventScreenTitle)
            dayMenuView.accessibilityHint = t("Swipe left or right to select day option.", "day menu a11y hint")
            descriptionView.accessibilityLabel = a(.EventDescription)
            locationItem.accessibilityLabel = a(.EventLocation)
            locationItem.accessibilityHint = t("Tap to toggle event location picker.", "location toolbar button a11y hint")
            saveItem.accessibilityLabel = a(.SaveEvent)
            timeItem.accessibilityLabel = a(.EventTime)
            timeItem.accessibilityHint = t("Tap to toggle event time picker.", "time toolbar button a11y hint")
            renderAccessibilityValueForElement(saveItem, value: false)
        }
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

        case (locationItem as UIBarButtonItem, let on as Bool):
            locationItem.accessibilityValue = on ? t("Event has location.", "location toolbar button a11y value") : nil

        case (saveItem as UIBarButtonItem, let on as Bool):
            let comment = "save toolbar button a11y value"
            saveItem.accessibilityValue = on ? t("Event is valid.", comment) : t("Event is invalid.", comment)

        case (timeItem as UIBarButtonItem, let on as Bool):
            timeItem.accessibilityValue = on ? t("Event has custom time.", "time toolbar button a11y value") : nil

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

    func renderAccessibilityValueForElement(element: AnyObject, value: AnyObject?) {
        switch (element, value) {

        case (titleView as NavigationTitleScrollView, let visibleItem as UIView):
            titleView.accessibilityValue = visibleItem.accessibilityLabel

        default: fatalError("Unsupported element, value.")
        }
    }

}
