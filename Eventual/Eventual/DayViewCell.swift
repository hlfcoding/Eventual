//
//  DayViewCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol DayViewCellRenderable: NSObjectProtocol {

    var dayText: String? { get set }
    var numberOfEvents: Int? { get set }

    func renderDayText(value: String)
    func renderIsToday(value: Bool)
    func renderNumberOfEvents(value: Int)

}

protocol DayViewCellRendering {}
extension DayViewCellRendering {

    static func renderCell(cell: DayViewCellRenderable, fromDayEvents dayEvents: DayEvents, dayDate: NSDate) {
        let dayText = NSDateFormatter.dayFormatter.stringFromDate(dayDate)
        if dayText != cell.dayText {
            cell.renderDayText(dayText)
            cell.dayText = dayText
        }

        let today = NSDate()
        cell.renderIsToday(dayDate.isEqualToDate(today.dayDate))

        if dayEvents.count != cell.numberOfEvents {
            cell.renderNumberOfEvents(dayEvents.count)
            cell.numberOfEvents = dayEvents.count
        }
    }

}

final class DayViewCell: CollectionViewTileCell, DayViewCellRenderable, DayViewCellRendering {

    @IBOutlet private var dayLabel: UILabel!
    @IBOutlet private var eventsLabel: UILabel!
    @IBOutlet private var labelSeparator: UIView!
    @IBOutlet private var todayIndicator: UIView!

    // MARK: - DayViewCellRendering

    var dayText: String?
    var numberOfEvents: Int?

    func renderDayText(value: String) { dayLabel.text = NSString(format: "%02ld", Int(value)!) as String }
    func renderIsToday(value: Bool) { todayIndicator.hidden = !value }
    func renderNumberOfEvents(value: Int) { eventsLabel.text = t("%d event(s)", "events label text on day tile", value) }

    // MARK: - CollectionViewTileCell

    override func prepareForReuse() {
        super.prepareForReuse()
        dayText = nil
        numberOfEvents = nil
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

    func setAccessibilityLabelsWithIndexPath(indexPath: NSIndexPath) {
        accessibilityLabel = NSString.localizedStringWithFormat(
            a(Label.FormatDayCell), indexPath.section, indexPath.item) as String
    }
    
}
