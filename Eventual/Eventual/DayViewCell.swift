//
//  DayViewCell.swift
//  Eventual
//
//  Created by Peng Wang on 7/26/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETDayViewCell) class DayViewCell : UICollectionViewCell {
    
    @IBOutlet weak var innerContentView: UIView!
    @IBOutlet private weak var dayLabel: UILabel!
    @IBOutlet private weak var eventsLabel: UILabel!
    @IBOutlet private weak var labelSeparator: UIView!
    @IBOutlet private weak var todayIndicator: UIView!
    
    // TODO: Not right i18n.
    private let singularEventsLabelFormat = NSLocalizedString("%d event", comment: "")
    private let pluralEventsLabelFormat = NSLocalizedString("%d events", comment: "")
    private var eventsLabelFormat: String {
    return (self.numberOfEvents > 1) ? pluralEventsLabelFormat : singularEventsLabelFormat
    }
    
    // MARK: Content
    
    var dayText: String?
    var isToday = false
    var numberOfEvents = 0
    
    // MARK: Borders
    
    var borderInsets: UIEdgeInsets!
    lazy var defaultBorderInsets :UIEdgeInsets = {
        return self.borderInsets
    }()
    
    // TODO: Struct.
    @IBOutlet private weak var borderTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var borderLeftConstraint: NSLayoutConstraint!
    @IBOutlet private weak var borderBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var borderRightConstraint: NSLayoutConstraint!
    
    func setAccessibilityLabelsWithIndexPath(indexPath :NSIndexPath) {}

}

extension DayViewCell { // MARK: Borders


}