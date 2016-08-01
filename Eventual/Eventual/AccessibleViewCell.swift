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
            NSLocalizedString("%d event(s) on %@", comment: "accessibility value on day tile"),
            numberOfEvents, NSDateFormatter.monthDayFormatter.stringFromDate(dayDate)) as String

    }

}
