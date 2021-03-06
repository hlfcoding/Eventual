//
//  AccessibleViewCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol AccessibleViewCell {

    func setUpAccessibility(at indexPath: IndexPath)
    func renderAccessibilityValue(_ value: Any?)

}

extension DayViewCell: AccessibleViewCell {

    func setUpAccessibility(at indexPath: IndexPath) {
        accessibilityLabel = String.localizedStringWithFormat(
            a(.formatDayCell), indexPath.section + 1, indexPath.item + 1) as String

    }

    func renderAccessibilityValue(_ value: Any?) {
        guard let numberOfEvents = numberOfEvents, let dayDate = dayDate else {
            accessibilityValue = nil
            return
        }
        if isRecurringEvents, let monthDate = monthDate {
            accessibilityValue = String.localizedStringWithFormat(
                NSLocalizedString("%d event(s) in %@", comment: "recurring day tile a11y value"),
                numberOfEvents, DateFormatter.monthFormatter.string(from: monthDate)) as String
        } else {
            accessibilityValue = String.localizedStringWithFormat(
                NSLocalizedString("%d event(s) on %@", comment: "day tile a11y value"),
                numberOfEvents, DateFormatter.monthDayFormatter.string(from: dayDate)) as String
        }

    }

}

extension EventViewCell: AccessibleViewCell {

    func setUpAccessibility(at indexPath: IndexPath) {
        accessibilityLabel = a(.formatEventCell, indexPath.item + 1)
    }

    func renderAccessibilityValue(_ value: Any?) {
        if let eventText = value as? String,
            let detailsText = detailsView.timeAndLocationLabel.attributedText {
            accessibilityValue = String.localizedStringWithFormat(
                NSLocalizedString("Event titled %@, at %@", comment: "event tile a11y value"),
                eventText, detailsText.string) as String
        } else {
            accessibilityValue = nil
        }

    }

}

extension MonthViewCell: AccessibleViewCell {

    func setUpAccessibility(at indexPath: IndexPath) {}

    func renderAccessibilityValue(_ value: Any?) {}

}
