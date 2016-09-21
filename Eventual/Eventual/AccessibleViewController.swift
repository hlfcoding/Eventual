//
//  AccessibleViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@objc protocol AccessibleViewController {

    func setUpAccessibility(specificElement: AnyObject?)
    @objc optional func renderAccessibilityValue(for element: AnyObject, value: AnyObject?)

}

extension DayViewController: AccessibleViewController {

    func setUpAccessibility(specificElement: AnyObject?) {
        switch specificElement {

        case let buttonItem as UIBarButtonItem:
            buttonItem.accessibilityLabel = a(.addDayEvent)

        case nil:
            collectionView!.accessibilityLabel = a(.dayEvents)

        default: fatalError("Unsupported element.")
        }
    }

}

extension EventViewController: AccessibleViewController {

    func setUpAccessibility(specificElement: AnyObject?) {
        switch specificElement {

        case drawerView as EventDatePickerDrawerView:
            dayDatePicker.accessibilityLabel = a(.pickDate)
            timeDatePicker.accessibilityLabel = a(.pickTime)

        default:
            dayLabel.accessibilityLabel = a(.eventDate)
            dayLabel.accessibilityHint = t("Tap to set a later date.", "day label a11y hint")
            dayMenuView.accessibilityLabel = a(.eventScreenTitle)
            dayMenuView.accessibilityHint = t("Swipe left or right to select day option.", "day menu a11y hint")
            descriptionView.accessibilityLabel = a(.eventDescription)
            locationItem.accessibilityLabel = a(.eventLocation)
            locationItem.accessibilityHint = t("Tap to toggle event location picker.", "location toolbar button a11y hint")
            saveItem.accessibilityLabel = a(.saveEvent)
            timeItem.accessibilityLabel = a(.eventTime)
            timeItem.accessibilityHint = t("Tap to toggle event time picker.", "time toolbar button a11y hint")
            renderAccessibilityValue(for: saveItem, value: false as AnyObject?)
        }
    }

    func renderAccessibilityValue(for element: AnyObject, value: AnyObject?) {
        switch (element, value) {

        case (dayLabel as UILabel, let date as Date?):
            guard let date = date else {
                dayLabel.accessibilityValue = nil
                break
            }
            dayLabel.accessibilityValue = DateFormatter.accessibleDateFormatter.string(from: date)

        case (dayMenuView as UIView, nil):
            if let visibleItem = dayMenuView.visibleItem,
                let optionLabel = DayMenuItem.from(view: visibleItem)?.labelText {
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
            buttonItem.accessibilityLabel = a(.addEvent)

        case nil:
            collectionView!.accessibilityLabel = a(.monthDays)

        default: fatalError("Unsupported element.")
        }
    }

    func renderAccessibilityValueForElement(element: AnyObject, value: AnyObject?) {
        switch (element, value) {

        case (let titleView as NavigationTitleScrollView, let visibleItem as UIView):
            titleView.accessibilityValue = visibleItem.accessibilityLabel

        default: fatalError("Unsupported element, value.")
        }
    }

}
