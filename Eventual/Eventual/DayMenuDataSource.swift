//
//  DayMenuDataSource.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

enum DayMenuItem: String {
    case Today, Tomorrow, Later

    var absoluteDate: NSDate {
        return NSDate().dayDateFromAddingDays(self.futureDayCount)
    }

    var futureDayCount: Int {
        switch self {
        case .Today: return 0
        case .Tomorrow: return 1
        case .Later: return 2
        }
    }

    var labelText: String {
        return t(self.rawValue).uppercaseString
    }

    var viewType: NavigationTitleItemType {
        switch self {
        case .Today, .Tomorrow: return .Label
        case .Later: return .Button
        }
    }

    static func fromAbsoluteDate(dayDate: NSDate) -> DayMenuItem {
        switch dayDate {
        case DayMenuItem.Today.absoluteDate: return .Today
        case DayMenuItem.Tomorrow.absoluteDate: return .Tomorrow
        default: return .Later
        }
    }

    static func fromLabelText(text: String) -> DayMenuItem {
        switch text {
        case DayMenuItem.Today.labelText: return .Today
        case DayMenuItem.Tomorrow.labelText: return .Tomorrow
        case DayMenuItem.Later.labelText: return .Later
        default: fatalError("Unsupported label text.")
        }
    }

    static func fromView(view: UIView) -> DayMenuItem? {
        let labelText: String!
        if let button = view as? UIButton {
            labelText = button.titleForState(.Normal)
        } else if let label = view as? UILabel {
            labelText = label.text
        } else {
            return nil
        }
        return DayMenuItem.fromLabelText(labelText)
    }
}

final class DayMenuDataSource {

    let todayIdentifier = DayMenuItem.Today.labelText
    let tomorrowIdentifier = DayMenuItem.Tomorrow.labelText
    let laterIdentifier = DayMenuItem.Later.labelText

    var positionedItems: [DayMenuItem] = [.Today, .Tomorrow, .Later]

    var dayIdentifier: String?

    func dateFromDayIdentifier(identifier: String) -> NSDate {
        return DayMenuItem.fromLabelText(identifier).absoluteDate
    }

    func identifierFromItem(item: UIView?) -> String? {
        guard let view = item else { return nil }
        return DayMenuItem.fromView(view)?.labelText
    }

    func indexFromDate(date: NSDate) -> Int {
        return self.positionedItems.indexOf(DayMenuItem.fromAbsoluteDate(date.dayDate))!
    }

    func itemAtIndex(index: Int) -> (NavigationTitleItemType, String) {
        let item = self.positionedItems[index]
        return (item.viewType, item.labelText)
    }

}
