//
//  DayViewCell.swift
//  Eventual
//
//  Created by Peng Wang on 7/26/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETDayViewCell) class DayViewCell: CollectionViewTileCell {
    
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
    
    // MARK: - Content
    
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
    
    // MARK: - CollectionViewTileCell
    
    override func setUp() {
        self.isAccessibilityElement = true
        super.setUp()
    }
    
    override func updateTintColorBasedAppearance() {
        super.updateTintColorBasedAppearance()
        self.dayLabel.textColor = self.tintColor
        self.labelSeparator.backgroundColor = self.tintColor
        self.todayIndicator.backgroundColor = self.tintColor
    }
    
    // MARK: - Public
    
    func setAccessibilityLabelsWithIndexPath(indexPath: NSIndexPath) {
        self.accessibilityLabel = NSString(
            format: t(ETLabel.FormatDayCell.toRaw()),
            indexPath.section, indexPath.item
        )
    }
}