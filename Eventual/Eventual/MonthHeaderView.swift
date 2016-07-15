//
//  MonthHeaderView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

final class MonthHeaderView: UICollectionReusableView {

    @IBOutlet var monthLabel: UILabel!

    var monthName: String? {
        didSet {
            if let monthName = monthName where monthName != oldValue {
                monthLabel.text = MonthHeaderView.formattedTextForText(monthName)
            }
        }
    }

    override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }

    class func formattedTextForText(text: NSString) -> String {
        return text.uppercaseString
    }
    
}
