//
//  MonthHeaderView.swift
//  Eventual
//
//  Created by Peng Wang on 12/28/15.
//  Copyright (c) 2015-2016 Eventual App. All rights reserved.
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
