//
//  DayMenuDataSource.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

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

final class DayMenuDataSource {

    var positionedItems: [DayMenuItem] = [.Today, .Tomorrow, .Later]

    var selectedItem: DayMenuItem?

    func indexFromDate(date: NSDate) -> Int {
        return self.positionedItems.indexOf(DayMenuItem.fromAbsoluteDate(date.dayDate))!
    }

}
