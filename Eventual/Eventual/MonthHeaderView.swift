//
//  MonthHeaderView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class MonthHeaderView: UICollectionReusableView {

    @IBOutlet var monthLabel: UILabel!

    var monthName: String? {
        didSet {
            if let monthName = self.monthName where monthName != oldValue {
                self.monthLabel.text = MonthHeaderView.formattedTextForText(monthName)
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
