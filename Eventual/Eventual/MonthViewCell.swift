//
//  MonthViewCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol MonthViewCellRenderable: NSObjectProtocol, AccessibleViewCell {

    var monthDate: Date? { get set }
    var numberOfDays: Int? { get set }

    func render(monthDate value: Date)
    func render(numberOfDays value: Int)

}

protocol MonthViewCellRendering {}
extension MonthViewCellRendering {

    static func render(cell: MonthViewCellRenderable,
                       fromMonthEvents monthEvents: MonthEvents, monthDate: Date) {
        cell.render(monthDate: monthDate)
        cell.monthDate = monthDate
        cell.render(numberOfDays: monthEvents.days.count)
        cell.numberOfDays = monthEvents.days.count
    }

    static func teardownRendering(for cell: MonthViewCellRenderable) {
        cell.monthDate = nil
        cell.numberOfDays = nil
    }

}

final class MonthViewCell: UICollectionViewCell, MonthViewCellRenderable, MonthViewCellRendering {

    @IBOutlet private(set) var daysLabel: UILabel!
    @IBOutlet private(set) var monthLabel: UILabel!
    @IBOutlet private(set) var tilesView: MonthTilesView!

    // MARK: - MonthViewCellRendering

    var monthDate: Date?
    var numberOfDays: Int?

    func render(monthDate value: Date) {
        monthLabel.text = DateFormatter.monthYearFormatter.string(from: value)
    }

    func render(numberOfDays value: Int) {
        daysLabel.text = t("%d day(s)", "days label text on month cell", value)
        tilesView.numberOfDays = value
    }

    // MARK: - UICollectionViewCell

    override func prepareForReuse() {
        super.prepareForReuse()
        MonthViewCell.teardownRendering(for: self)
    }

}
