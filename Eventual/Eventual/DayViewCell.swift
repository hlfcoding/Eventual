//
//  DayViewCell.swift
//  Eventual
//
//  Created by Peng Wang on 7/26/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
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
            if let dayText = self.dayText where dayText != oldValue {
                self.dayLabel.text = NSString(format: "%02ld", dayText.toInt()!) as? String
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
            if self.numberOfEvents != oldValue {
                self.eventsLabel.text = NSString(format: self.eventsLabelFormat, self.numberOfEvents) as? String
            }
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
            format: t(ETLabel.FormatDayCell.rawValue),
            indexPath.section, indexPath.item
        ) as? String
    }
}