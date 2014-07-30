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
    
    var dayText: String? {
    didSet {
        if oldValue == self.dayText { return }
        self.dayLabel.text = NSString(format: "%02ld", self.dayText!.bridgeToObjectiveC().integerValue)
    }
    }
    var isToday: Bool = false {
    didSet {
        self.todayIndicator.hidden = !self.isToday
    }
    }
    var numberOfEvents: Int = 0 {
    didSet {
        if oldValue == self.numberOfEvents { return }
        self.eventsLabel.text = NSString(format: self.eventsLabelFormat, self.numberOfEvents)
    }
    }
    
    // MARK: Borders
    
    var borderInsets: UIEdgeInsets!
    var defaultBorderInsets: UIEdgeInsets!
    
    // TODO: Struct.
    @IBOutlet private weak var borderTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var borderLeftConstraint: NSLayoutConstraint!
    @IBOutlet private weak var borderBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var borderRightConstraint: NSLayoutConstraint!
    
    func setAccessibilityLabelsWithIndexPath(indexPath: NSIndexPath) {
        self.accessibilityLabel = NSString(
            format: NSLocalizedString(ETLabel.FormatDayCell.toRaw(), comment: ""),
            indexPath.section, indexPath.item
        )
    }
    
    init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        self.setUp()
    }
    
    private func setUp() {
        self.isAccessibilityElement = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.completeSetup()
    }
    
    private func completeSetup() {
        self.borderInsets = UIEdgeInsets(
            top: self.borderTopConstraint.constant, left: self.borderLeftConstraint.constant,
            bottom: self.borderBottomConstraint.constant, right: self.borderRightConstraint.constant
        )
        self.defaultBorderInsets = self.borderInsets
    }
}