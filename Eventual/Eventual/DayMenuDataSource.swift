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
        return NSDate().dayDateFromAddingDays(futureDayCount)
    }

    var futureDayCount: Int {
        switch self {
        case .Today: return 0
        case .Tomorrow: return 1
        case .Later: return 2
        }
    }

    var labelText: String {
        return t(rawValue).uppercaseString
    }

    var viewType: NavigationTitleItemType {
        switch self {
        case .Today, .Tomorrow: return .Label
        case .Later: return .Button
        }
    }

}

extension DayMenuItem {

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

final class DayMenuDataSource: NSObject {

    var positionedItems: [DayMenuItem] = [.Today, .Tomorrow, .Later]

    var selectedItem: DayMenuItem?

    func indexFromDate(date: NSDate) -> Int {
        return positionedItems.indexOf(DayMenuItem.fromAbsoluteDate(date.dayDate))!
    }

}

// MARK: - NavigationTitleScrollViewDataSource

extension DayMenuDataSource: NavigationTitleScrollViewDataSource {

    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int {
        return positionedItems.count
    }

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView,
                                   itemAtIndex index: Int) -> UIView? {
        let item = positionedItems[index]
        guard let itemView = scrollView.newItemOfType(item.viewType, withText: item.labelText) else { return nil }
        itemView.accessibilityLabel = a(.FormatDayOption, item.rawValue)
        itemView.accessibilityHint = scrollView.accessibilityHint
        return itemView
    }

}
