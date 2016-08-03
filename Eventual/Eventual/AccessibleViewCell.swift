//
//  AccessibleViewCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol AccessibleViewCell {

    func setUpAccessibilityWithIndexPath(indexPath: NSIndexPath)
    func renderAccessibilityValue(value: AnyObject?)

}

extension DayViewCell: AccessibleViewCell {

    func setUpAccessibilityWithIndexPath(indexPath: NSIndexPath) {
        accessibilityLabel = NSString.localizedStringWithFormat(
            a(.FormatDayCell), indexPath.section + 1, indexPath.item + 1) as String

    }

    func renderAccessibilityValue(value: AnyObject?) {
        guard let numberOfEvents = numberOfEvents, dayDate = dayDate else {
            accessibilityValue = nil
            return
        }
        accessibilityValue = NSString.localizedStringWithFormat(
            NSLocalizedString("%d event(s) on %@", comment: "day tile a11y value"),
            numberOfEvents, NSDateFormatter.monthDayFormatter.stringFromDate(dayDate)) as String

    }

}

extension EventViewCell: AccessibleViewCell {

    func setUpAccessibilityWithIndexPath(indexPath: NSIndexPath) {
        accessibilityLabel = a(.FormatEventCell, indexPath.item + 1)
    }

    func renderAccessibilityValue(value: AnyObject?) {
        if let
            eventText = value as? String,
            detailsText = detailsView.timeAndLocationLabel.attributedText {
            accessibilityValue = NSString.localizedStringWithFormat(
                NSLocalizedString("Event titled %@, at %@", comment: "event tile a11y value"),
                eventText, detailsText.string) as String
        } else {
            accessibilityValue = nil
        }

    }

}
