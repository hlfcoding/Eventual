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
            guard let monthName = monthName, monthName != oldValue else { return }
            monthLabel.text = MonthHeaderView.formattedText(for: monthName)
        }
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override init(frame: CGRect) {
        preconditionFailure("Can only be initialized from nib.")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    class func formattedText(for text: String) -> String {
        return text.uppercased()
    }

}
