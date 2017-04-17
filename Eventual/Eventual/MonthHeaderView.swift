//
//  MonthHeaderView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

final class MonthHeaderView: UICollectionReusableView {

    @IBOutlet private(set) var monthLabel: UILabel!

    var monthDate: Date? {
        didSet {
            guard let monthDate = monthDate, monthDate != oldValue else { return }
            monthLabel.text = MonthHeaderView.formattedText(for: monthDate)
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

    static func formattedText(for monthDate: Date) -> String {
        return DateFormatter.monthFormatter.string(from: monthDate).uppercased()
    }

}
