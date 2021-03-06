//
//  DayMenuDataSource.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

enum DayMenuItem: String {

    case today, tomorrow, later

    var absoluteDate: Date {
        return Date().dayDate(byAddingDays: futureDayCount)
    }

    var futureDayCount: Int {
        switch self {
        case .today: return 0
        case .tomorrow: return 1
        case .later: return 2
        }
    }

    var labelText: String {
        return t(rawValue).uppercased()
    }

    var viewType: TitleItemType {
        switch self {
        case .today, .tomorrow: return .label
        case .later: return .button
        }
    }

}

extension DayMenuItem {

    static func from(dayDate: Date) -> DayMenuItem {
        switch dayDate {
        case DayMenuItem.today.absoluteDate: return .today
        case DayMenuItem.tomorrow.absoluteDate: return .tomorrow
        default: return .later
        }
    }

    static func from(labelText: String) -> DayMenuItem {
        switch labelText {
        case DayMenuItem.today.labelText: return .today
        case DayMenuItem.tomorrow.labelText: return .tomorrow
        case DayMenuItem.later.labelText: return .later
        default: fatalError("Unsupported label text.")
        }
    }

    static func from(view: UIView) -> DayMenuItem? {
        let labelText: String!
        if let button = view as? UIButton {
            labelText = button.title(for: .normal)
        } else if let label = view as? UILabel {
            labelText = label.text
        } else {
            return nil
        }
        return DayMenuItem.from(labelText: labelText)
    }

}

final class DayMenuDataSource: NSObject {

    var positionedItems: [DayMenuItem] = [.today, .tomorrow, .later]

    var selectedItem: DayMenuItem?

    func itemIndex(from date: Date) -> Int {
        return positionedItems.index(of: DayMenuItem.from(dayDate: date.dayDate))!
    }

}

// MARK: - TitleScrollViewDataSource

extension DayMenuDataSource: TitleScrollViewDataSource {

    func titleScrollViewItemCount(_ scrollView: TitleScrollView) -> Int {
        return positionedItems.count
    }

    func titleScrollView(_ scrollView: TitleScrollView, itemAt index: Int) -> UIView? {
        let item = positionedItems[index]
        let itemView = scrollView.newItem(type: item.viewType, text: item.labelText)
        itemView.accessibilityLabel = a(.formatDayOption, item.rawValue)
        itemView.accessibilityHint = scrollView.accessibilityHint
        return itemView
    }

}
