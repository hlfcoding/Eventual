//
//  Additions.swift
//  Eventual
//
//  Created by Peng Wang on 7/29/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

import CoreLocation
import EventKit
import MapKit

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

    /**
     New date based on this date where everything smaller than the day component is 0.
     `numberOfDays` can be negative to get an earlier date.
     */
    func dayDateFromAddingDays(numberOfDays: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = numberOfDays
        return calendar.dateByAddingComponents(components, toDate: self, options: [])!.dayDate!
    }

    /**
     New date based on this date where everything smaller than the hour component is 0.
     `numberOfDays` can be negative to get an earlier date.
     */
    func hourDateFromAddingHours(numberOfHours: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.hour = numberOfHours
        return calendar.dateByAddingComponents(components, toDate: self, options: [])!.hourDate!
    }

    var hasCustomTime: Bool {
        return self != self.dayDate
    }

    /**
     New date based on this date, combined with `timeDate`'s time components.
     */
    func dateWithTime(timeDate: NSDate) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let timeComponents = calendar.components([.Hour, .Minute, .Second], fromDate: timeDate)
        return calendar.dateBySettingHour(timeComponents.hour, minute: timeComponents.minute, second: timeComponents.second, ofDate: self, options: [.WrapComponents])!
    }

    private func flooredDateWithComponents(unitFlags: NSCalendarUnit) -> NSDate? {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(calendar.components(unitFlags, fromDate: self))
    }

    /** Clone except everything smaller than the day component is 0. */
    var dayDate: NSDate? { return self.flooredDateWithComponents(DayUnitFlags) }

    /** Clone except everything smaller than the hour component is 0. */
    var hourDate: NSDate? { return self.flooredDateWithComponents(HourUnitFlags) }

    /** Clone except everything smaller than the month component is 0. */
    var monthDate: NSDate? { return self.flooredDateWithComponents(MonthUnitFlags) }

}

extension NSDateFormatter {

    // NOTE: This memory can never be freed as long as app is active. But since every screen
    // requires at least one form of formatting, it's reasonable to always keep this in memory.
    private static var sharedDateFormatter = NSDateFormatter()

    private static func sharedDateFormatterWithFormat(dateFormat: String) -> NSDateFormatter {
        let formatter = NSDateFormatter.sharedDateFormatter
        formatter.dateFormat = dateFormat
        return formatter
    }

    static var dayFormatter: NSDateFormatter { return NSDateFormatter.sharedDateFormatterWithFormat("d") }

    static var dateFormatter: NSDateFormatter { return NSDateFormatter.sharedDateFormatterWithFormat("MMMM d, y · EEEE") }

    static var monthFormatter: NSDateFormatter { return NSDateFormatter.sharedDateFormatterWithFormat("MMMM") }

    static var monthDayFormatter: NSDateFormatter { return NSDateFormatter.sharedDateFormatterWithFormat("MMMM d") }

    static var timeFormatter: NSDateFormatter { return NSDateFormatter.sharedDateFormatterWithFormat("h:mm a") }

}

extension String {

    /**
     Addition. A simple JSON-like debug formatter.
     */
    static func debugDescriptionForGroupWithLabel(label: String, attributes: [String: AnyObject?],
                                                  indentLevel: Int = 0) -> String
    {
        let tab = Character("\t")
        let outerIndent = String(count: indentLevel, repeatedValue: tab)
        let innerIndent = String(count: indentLevel + 1, repeatedValue: tab)
        return (
            "\(outerIndent)\(label): {\n" +
            attributes.reduce("") { $0 + "\(innerIndent)\($1.0): \($1.1)\n" } +
            "\(outerIndent)}\n"
        )
    }

}

extension UICollectionView {

    /**
     Addition. `-cellForItemAtIndexPath:` returns a cell optional, nil when index path isn't visible
     or invalid. This method wraps that with the call to the `dataSource` method, so a cell is
     created and rendered only if needed, whereas always calling the dataSource method may be less
     performant, even more than just re-configuring the cell.
    */
    func guaranteedCellForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = self.cellForItemAtIndexPath(indexPath) else {
            guard let dataSource = self.dataSource else { fatalError("Delegate is required.") }
            return dataSource.collectionView(self, cellForItemAtIndexPath: indexPath)
        }
        return cell
    }

}

extension UINavigationBar {

    func applyCustomBorderColor(color: UIColor, backgroundColor: UIColor = UIColor(white: 1.0, alpha: 0.95)) {
        // Temporary appearance changes.
        for view in self.subviews {
            view.backgroundColor = UIColor.clearColor()
        }
        // Custom bar border color, at the cost of translucency.
        let height = self.frame.height + UIApplication.sharedApplication().statusBarFrame.height
        let image = color_image(backgroundColor, size: CGSize(width: self.frame.width, height: height))
        self.setBackgroundImage(image, forBarMetrics: .Default)
        self.shadowImage = color_image(color, size: CGSize(width: self.frame.width, height: 1.0))

    }
}

extension UIView {

    /**
     Addition. Animates layout constraint changes immediately, with animation and spring options
     that have an app-specific base.
     */
    func animateLayoutChangesWithDuration(duration: NSTimeInterval, usingSpring: Bool = true,
                                          options: UIViewAnimationOptions, completion: ((Bool) -> Void)?)
    {
        var animationOptions = options
        animationOptions.insert(.BeginFromCurrentState)
        let animations = { self.layoutIfNeeded() }
        self.setNeedsUpdateConstraints()
        if usingSpring {
            UIView.animateWithDuration( duration, delay: 0.0,
                usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0,
                options: animationOptions, animations: animations, completion: completion
            )
        } else {
            UIView.animateWithDuration( duration, delay: 0.0,
                options: animationOptions, animations: animations, completion: completion
            )
        }

    }

}

extension UIViewController {

    /**
     Addition. This should be called after initialization, preferably in `viewDidLoad`. It will
     detect and customize the `navigationItem` with app-specific transforms.
     */
    func customizeNavigationItem() {
        if let title = self.navigationItem.title {
            self.navigationItem.title = title.uppercaseString
        }

        if let buttonItem = self.navigationItem.leftBarButtonItem where buttonItem.title == Label.NavigationBack.rawValue,
           let iconFont = UIFont(name: FontName, size: AppearanceManager.defaultManager.iconBarButtonItemFontSize)
        {
            buttonItem.setTitleTextAttributes([ NSFontAttributeName: iconFont ], forState: .Normal)
            buttonItem.title = Icon.LeftArrow.rawValue
        }
    }

}

extension EKEvent {

    /**
     Addition. Apparently `location` can be initialized as an empty string, so that needs to be
     checked too.
     */
    var hasLocation: Bool {
        guard let location = self.location where !location.isEmpty else { return false }
        return true
    }

    /**
     Addition. `EKEvent` doesn't store location as a `CLPlacemark`, much less an `MKMapItem`.
     Additional geocoding with the address string is needed to get matching `CLPlacemark`(s).
     */
    func fetchLocationPlacemarkIfNeeded(completionHandler: CLGeocodeCompletionHandler) {
        guard self.hasLocation else { return }

        // TODO: Throw for rate-limiting and handle those exceptions.
        CLGeocoder().geocodeAddressString(self.location!, completionHandler: completionHandler)
    }

}
