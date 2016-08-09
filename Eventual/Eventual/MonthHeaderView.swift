//
//  MonthHeaderView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

final class MonthHeaderView: UICollectionReusableView {

    @IBOutlet private(set) var monthLabel: UILabel!

    var monthName: String? {
        didSet {
            guard let monthName = monthName where monthName != oldValue else { return }
            monthLabel.text = MonthHeaderView.formattedTextForText(monthName)
        }
    }

    override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }

    class func formattedTextForText(text: NSString) -> String {
        return text.uppercaseString
    }

}
