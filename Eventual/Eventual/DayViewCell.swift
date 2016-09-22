//
//  DayViewCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol DayViewCellRenderable: NSObjectProtocol, AccessibleViewCell {

    var dayDate: Date? { get set }
    var numberOfEvents: Int? { get set }

    func render(dayText value: Date)
    func render(isToday value: Bool)
    func render(numberOfEvents value: Int)

}

protocol DayViewCellRendering {}
extension DayViewCellRendering {

    static func render(cell: DayViewCellRenderable, fromDayEvents dayEvents: DayEvents, dayDate: Date) {
        let changed = (dayDate: dayDate != cell.dayDate,
                       numberOfEvents: dayEvents.count != cell.numberOfEvents)

        let today = Date().dayDate
        cell.render(isToday: dayDate == today)

        if changed.dayDate {
            cell.render(dayText: dayDate)
            cell.dayDate = dayDate
        }

        if changed.numberOfEvents {
            cell.render(numberOfEvents: dayEvents.count)
            cell.numberOfEvents = dayEvents.count
        }

        if changed.dayDate && changed.numberOfEvents {
            cell.renderAccessibilityValue(nil)
        }
    }

    static func teardownRendering(for cell: DayViewCellRenderable) {
        cell.dayDate = nil
        cell.numberOfEvents = nil
    }

}

final class DayViewCell: CollectionViewTileCell, DayViewCellRenderable, DayViewCellRendering {

    @IBOutlet private var dayLabel: UILabel!
    @IBOutlet private var eventsLabel: UILabel!
    @IBOutlet private var labelSeparator: UIView!
    @IBOutlet private var todayIndicator: UIView!

    private var isTodayIndicatorHidden = false

    // MARK: - DayViewCellRendering

    var dayDate: Date?
    var numberOfEvents: Int?

    func render(dayText value: Date) {
        dayLabel.text = NSString(format: "%02ld", Int(DateFormatter.dayFormatter.string(from: value))!) as String
    }

    func render(isToday value: Bool) {
        todayIndicator.isHidden = !value
        isTodayIndicatorHidden = !value
    }

    func render(numberOfEvents value: Int) {
        eventsLabel.text = t("%d event(s)", "events label text on day tile", value)
    }

    // MARK: - CollectionViewTileCell

    override var staticContentSubviews: [UIView] {
        return innerContentView.subviews
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        DayViewCell.teardownRendering(for: self)
    }

    override func toggleContent(visible: Bool) {
        super.toggleContent(visible: visible)
        todayIndicator.isHidden = visible ? isTodayIndicatorHidden : true
    }

    override func updateTintColorBasedAppearance() {
        super.updateTintColorBasedAppearance()
        dayLabel.textColor = tintColor
        labelSeparator.backgroundColor = tintColor
        todayIndicator.backgroundColor = tintColor
    }

}
