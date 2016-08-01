//
//  DayViewCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol DayViewCellRenderable: NSObjectProtocol, AccessibleViewCell {

    var dayDate: NSDate? { get set }
    var numberOfEvents: Int? { get set }

    func renderDayText(value: NSDate)
    func renderIsToday(value: Bool)
    func renderNumberOfEvents(value: Int)

}

protocol DayViewCellRendering {}
extension DayViewCellRendering {

    static func renderCell(cell: DayViewCellRenderable, fromDayEvents dayEvents: DayEvents, dayDate: NSDate) {
        let changed = (dayDate: dayDate != cell.dayDate,
                       numberOfEvents: dayEvents.count != cell.numberOfEvents)

        let today = NSDate().dayDate
        cell.renderIsToday(dayDate.isEqualToDate(today))

        if changed.dayDate {
            cell.renderDayText(dayDate)
            cell.dayDate = dayDate
        }

        if changed.numberOfEvents {
            cell.renderNumberOfEvents(dayEvents.count)
            cell.numberOfEvents = dayEvents.count
        }

        if changed.dayDate && changed.numberOfEvents {
            cell.renderAccessibilityValue(nil)
        }
    }

    static func teardownCellRendering(cell: DayViewCellRenderable) {
        cell.dayDate = nil
        cell.numberOfEvents = nil
    }

}

final class DayViewCell: CollectionViewTileCell, DayViewCellRenderable, DayViewCellRendering {

    @IBOutlet private var dayLabel: UILabel!
    @IBOutlet private var eventsLabel: UILabel!
    @IBOutlet private var labelSeparator: UIView!
    @IBOutlet private var todayIndicator: UIView!

    // MARK: - DayViewCellRendering

    var dayDate: NSDate?
    var numberOfEvents: Int?

    func renderDayText(value: NSDate) {
        dayLabel.text = NSString(format: "%02ld", Int(NSDateFormatter.dayFormatter.stringFromDate(value))!) as String
    }

    func renderIsToday(value: Bool) {
        todayIndicator.hidden = !value
    }

    func renderNumberOfEvents(value: Int) {
        eventsLabel.text = t("%d event(s)", "events label text on day tile", value)
    }

    // MARK: - CollectionViewTileCell

    override func prepareForReuse() {
        super.prepareForReuse()
        DayViewCell.teardownCellRendering(self)
    }

    override func updateTintColorBasedAppearance() {
        super.updateTintColorBasedAppearance()
        dayLabel.textColor = tintColor
        labelSeparator.backgroundColor = tintColor
        todayIndicator.backgroundColor = tintColor
    }

    // MARK: - Public

    override var staticContentSubviews: [UIView] {
        return innerContentView.subviews.filter { subview in
            return subview != todayIndicator
        }
    }

}
