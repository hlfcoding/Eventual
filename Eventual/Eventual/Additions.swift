//
//  Additions.swift
//  Eventual
//
//  Created by Peng Wang on 7/29/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

// MARK: - Helpers

func t(key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

func dispatch_after(duration: NSTimeInterval, block: dispatch_block_t!) {
    let time = Int64(duration * Double(NSEC_PER_SEC))
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time), dispatch_get_main_queue(), block)
}

func color_image(color: UIColor, size: CGSize) -> UIImage {
    UIGraphicsBeginImageContext(size)
    let path = UIBezierPath(rect: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
    color.setFill()
    path.fill()
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

func debug_view(view: UIView) {
    view.layer.borderWidth = 1.0
    view.layer.borderColor = UIColor.redColor().CGColor
}

// MARK: - Extensions

extension NSDate {

    func dayDateFromAddingDays(numberOfDays: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = numberOfDays
        return calendar.dateByAddingComponents(components, toDate: self, options: [])!.dayDate!
    }

    func hourDateFromAddingHours(numberOfHours: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.hour = numberOfHours
        return calendar.dateByAddingComponents(components, toDate: self, options: [])!.hourDate!
    }

    var hasCustomTime: Bool {
        return self != self.dayDate
    }

    func dateWithTime(timeDate: NSDate) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let timeComponents = calendar.components([.Hour, .Minute, .Second], fromDate: timeDate)
        return calendar.dateBySettingHour(timeComponents.hour, minute: timeComponents.minute, second: timeComponents.second, ofDate: self, options: [.WrapComponents])!
    }

    func flooredDateWithComponents(unitFlags: NSCalendarUnit) -> NSDate? {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(calendar.components(unitFlags, fromDate: self))
    }

    var dayDate: NSDate? { return self.flooredDateWithComponents(DayUnitFlags) }
    var hourDate: NSDate? { return self.flooredDateWithComponents(HourUnitFlags) }
    var monthDate: NSDate? { return self.flooredDateWithComponents(MonthUnitFlags) }

}

extension UICollectionView {

    /**
     `-cellForItemAtIndexPath:` returns a cell optional, nil when index path isn't visible or
     invalid. This method wraps that with the call to the `dataSource` method, so a cell is
     created and rendered only if needed, whereas always calling the dataSource method may be
     less performant, even more than just re-configuring the cell.
    */
    func guaranteedCellForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = self.cellForItemAtIndexPath(indexPath) else {
            guard let dataSource = self.dataSource else { fatalError("Delegate is required.") }
            return dataSource.collectionView(self, cellForItemAtIndexPath: indexPath)
        }
        return cell
    }

}