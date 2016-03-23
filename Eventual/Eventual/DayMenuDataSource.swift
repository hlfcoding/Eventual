//
//  DayMenuDataSource.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class DayMenuDataSource: NSObject {

    let todayIdentifier: String = t("Today").uppercaseString
    let tomorrowIdentifier: String = t("Tomorrow").uppercaseString
    let laterIdentifier: String = t("Later").uppercaseString

    var orderedIdentifiers: [String] {
        return [self.todayIdentifier, self.tomorrowIdentifier, self.laterIdentifier]
    }

    var dayIdentifier: String?

    func dateFromDayIdentifier(identifier: String) -> NSDate {
        let numberOfDays: Int!
        switch identifier {
        case self.tomorrowIdentifier: numberOfDays = 1
        case self.laterIdentifier: numberOfDays = 2
        default: numberOfDays = 0
        }
        return NSDate().dayDateFromAddingDays(numberOfDays)
    }

    func identifierFromItem(item: UIView?) -> String? {
        var identifier: String?
        if let button = item as? UIButton {
            identifier = button.titleForState(.Normal)
        } else if let label = item as? UILabel {
            identifier = label.text
        }
        return identifier
    }

    func indexFromDate(date: NSDate) -> Int {
        let index: Int!
        let normalizedDate = date.dayDate
        if normalizedDate == self.dateFromDayIdentifier(self.todayIdentifier) {
            index = self.orderedIdentifiers.indexOf { $0 == self.todayIdentifier }!
        } else if normalizedDate == self.dateFromDayIdentifier(self.tomorrowIdentifier) {
            index = self.orderedIdentifiers.indexOf { $0 == self.tomorrowIdentifier }!
        } else {
            index = self.orderedIdentifiers.indexOf { $0 == self.laterIdentifier }!
        }
        return index
    }

    func itemAtIndex(index: Int) -> (NavigationTitleItemType, String) {
        let identifier = self.orderedIdentifiers[index], buttonIdentifiers = [self.laterIdentifier]
        let type: NavigationTitleItemType = buttonIdentifiers.contains(identifier) ? .Button : .Label
        return (type, identifier)
    }

}
