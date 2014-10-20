//
//  DayViewCell.swift
//  Eventual
//
//  Created by Peng Wang on 7/26/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETDayViewCell) class DayViewCell: UICollectionViewCell {
    
    @IBOutlet var innerContentView: UIView!
    @IBOutlet private var dayLabel: UILabel!
    @IBOutlet private var eventsLabel: UILabel!
    @IBOutlet private var labelSeparator: UIView!
    @IBOutlet private var todayIndicator: UIView!
    
    // TODO: Not right i18n.
    private let singularEventsLabelFormat = t("%d event")
    private let pluralEventsLabelFormat = t("%d events")
    private var eventsLabelFormat: String {
    return (self.numberOfEvents > 1) ? pluralEventsLabelFormat : singularEventsLabelFormat
    }
    
    // MARK: Content
    
    var dayText: String? {
        didSet {
            if oldValue == self.dayText { return }
            if let dayText = self.dayText {
                self.dayLabel.text = NSString(format: "%02ld", dayText.toInt()!)
            }
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
    
    var borderInsets: UIEdgeInsets! {
        didSet {
            self.borderTopConstraint.constant = self.borderInsets.top
            self.borderLeftConstraint.constant = self.borderInsets.left
            self.borderBottomConstraint.constant = self.borderInsets.bottom
            self.borderRightConstraint.constant = self.borderInsets.right
        }
    }
    var defaultBorderInsets: UIEdgeInsets!
    
    // TODO: Struct.
    @IBOutlet private var borderTopConstraint: NSLayoutConstraint!
    @IBOutlet private var borderLeftConstraint: NSLayoutConstraint!
    @IBOutlet private var borderBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var borderRightConstraint: NSLayoutConstraint!
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    required init(coder aDecoder: NSCoder) {
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
        self.updateTintColorBasedAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.innerContentView.layer.removeAllAnimations()
        self.innerContentView.transform = CGAffineTransformIdentity
    }
    
    override func tintColorDidChange() {
        self.updateTintColorBasedAppearance()
    }
    
    private func updateTintColorBasedAppearance() {
        self.backgroundColor = self.tintColor
        self.dayLabel.textColor = self.tintColor
        self.labelSeparator.backgroundColor = self.tintColor
        self.todayIndicator.backgroundColor = self.tintColor
    }
    
    // MARK: Public
    
    func setAccessibilityLabelsWithIndexPath(indexPath: NSIndexPath) {
        self.accessibilityLabel = NSString(
            format: t(ETLabel.FormatDayCell.toRaw()),
            indexPath.section, indexPath.item
        )
    }
}