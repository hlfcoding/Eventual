//
//  Additions.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

import EventKit

// MARK: - Helpers

/**
 `t` is short for `translate` (via Rails) and shortens UI text translation code.
 - parameter comment: Optional, but useful for the translator.
 - parameter argument: Singular and not variadic supported because Swift doesn't have splats.
 */
func t<Key: StringLiteralConvertible>(key: Key, _ comment: String? = "", _ argument: CVarArgType? = nil) -> String {
    let localized = NSLocalizedString(String(key), comment: comment!)
    if let argument = argument {
        return NSString.localizedStringWithFormat(localized, argument) as String
    }
    return localized
}

/**
 `a` is short for `accessibility` and shortens accessibility label code.
 - parameter argument: Singular and not variadic supported because Swift doesn't have splats.
 */
func a(key: Label, _ argument: CVarArgType? = nil) -> String {
    return t(key.rawValue, "accessibility", argument)
}

func dispatchAfter(duration: NSTimeInterval, block: dispatch_block_t!) {
    let time = Int64(duration * Double(NSEC_PER_SEC))
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time), dispatch_get_main_queue(), block)
}

class NotificationPayload {

    private static let key = "payload"

    var userInfo: UserInfo { return [ NotificationPayload.key: self ] }

}

// MARK: - Extensions

extension NSCalendarUnit {

    static let dayUnitFlags: NSCalendarUnit = [.Day, .Month, .Year]
    static let hourUnitFlags: NSCalendarUnit = [.Hour, .Day, .Month, .Year]
    static let monthUnitFlags: NSCalendarUnit = [.Month, .Year]

}

extension NSDate {

    /**
     New date based on this date where everything smaller than the day component is 0.
     `numberOfDays` can be negative to get an earlier date.
     */
    func dayDateFromAddingDays(numberOfDays: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar(), components = NSDateComponents()
        components.day = numberOfDays
        return calendar.dateByAddingComponents(components, toDate: self, options: [])!.dayDate
    }

    /**
     New date based on this date where everything smaller than the hour component is 0.
     `numberOfDays` can be negative to get an earlier date.
     */
    func hourDateFromAddingHours(numberOfHours: Int) -> NSDate {
        let calendar = NSCalendar.currentCalendar(), components = NSDateComponents()
        components.hour = numberOfHours
        return calendar.dateByAddingComponents(components, toDate: self, options: [])!.hourDate
    }

    var hasCustomTime: Bool {
        return self != dayDate
    }

    /**
     New date based on this date, combined with `timeDate`'s time components.
     */
    func dateWithTime(timeDate: NSDate) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let timeComponents = calendar.components([.Hour, .Minute, .Second], fromDate: timeDate)
        return calendar.dateBySettingHour(timeComponents.hour, minute: timeComponents.minute, second: timeComponents.second, ofDate: self, options: [.WrapComponents])!
    }

    /**
     This conversion from a valid `NSDate` to normalized `NSDateComponents` and back is obviously
     safe, hence the forced unwrapping.
     */
    private func flooredDateWithComponents(unitFlags: NSCalendarUnit) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        return calendar.dateFromComponents(calendar.components(unitFlags, fromDate: self))!
    }

    /** Clone except everything smaller than the day component is 0. */
    var dayDate: NSDate { return flooredDateWithComponents(NSCalendarUnit.dayUnitFlags) }

    /** Clone except everything smaller than the hour component is 0. */
    var hourDate: NSDate { return flooredDateWithComponents(NSCalendarUnit.hourUnitFlags) }

    /** Clone except everything smaller than the month component is 0. */
    var monthDate: NSDate { return flooredDateWithComponents(NSCalendarUnit.monthUnitFlags) }

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

    static var accessibleDateFormatter: NSDateFormatter { return NSDateFormatter.sharedDateFormatterWithFormat("EEEE, MMMM d, y") }

}

extension Dictionary {

    func notificationUserInfoPayload() -> AnyObject? {
        return ((self as? AnyObject) as? UserInfo)?[NotificationPayload.key]
    }
    
}

extension String {

    /**
     Addition. A simple JSON-like debug formatter.
     */
    static func debugDescriptionForGroupWithLabel(label: String, attributes: [String: AnyObject?],
                                                  indentLevel: Int = 0) -> String {
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

extension UILabel {

    var icon: Icon? {
        get {
            guard let text = text else { return nil }
            return Icon(rawValue: text)
        }
        set {
            let fontSize = Appearance.iconBarButtonItemFontSize
            if font.fontName != Appearance.fontName, let iconFont = UIFont(name: Appearance.fontName, size: fontSize) {
                font = iconFont
            }
            text = newValue?.rawValue
        }
    }

}

extension UIView {

    /**
     Addition. Animates layout constraint changes immediately, with animation and spring options
     that have an app-specific base.
     */
    func animateLayoutChangesWithDuration(duration: NSTimeInterval, usingSpring: Bool = true,
                                          options: UIViewAnimationOptions, completion: ((Bool) -> Void)?) {
        let animations = { self.layoutIfNeeded() }
        setNeedsUpdateConstraints()
        if usingSpring {
            let (damping, initialVelocity) = Appearance.drawerSpringAnimation
            UIView.animateWithDuration(
                duration, delay: 0,
                usingSpringWithDamping: damping, initialSpringVelocity: initialVelocity,
                options: options, animations: animations, completion: completion
            )
        } else {
            UIView.animateWithDuration(
                duration, delay: 0,
                options: options, animations: animations, completion: completion
            )
        }

    }

    /**
     Addition. Pythagoras distance based durations. `time = distance / rate`
     */
    static func durationForAnimatingBetweenPoints(points: (CGPoint, CGPoint),
                                                  withVelocity pointsPerSecond: Double) -> NSTimeInterval {
        let (a, b) = points
        let distance = Double(sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2)))
        return distance / pointsPerSecond
    }

}

extension UIViewController {

    /**
     Addition. This should be called after initialization, preferably in `viewDidLoad`. It will
     detect and customize the `navigationItem` with app-specific transforms.
     */
    func customizeNavigationItem() {
        if let title = navigationItem.title {
            navigationItem.title = title.uppercaseString
        }

        func customizeBackLeftItem() {
            guard let buttonItem = navigationItem.leftBarButtonItem where buttonItem.title == Label.NavigationBack.rawValue else { return }
            guard let iconFont = UIFont(name: Appearance.fontName, size: Appearance.iconBarButtonItemFontSize) else { return }
            buttonItem.setTitleTextAttributes([ NSFontAttributeName: iconFont ], forState: .Normal)
            buttonItem.accessibilityLabel = a(.NavigationBack)
            buttonItem.title = Icon.LeftArrow.rawValue
        }

        customizeBackLeftItem()
    }

}
