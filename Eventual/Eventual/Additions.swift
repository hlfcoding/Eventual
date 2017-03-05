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
func t<Key: ExpressibleByStringLiteral>(_ key: Key, _ comment: String? = "", _ argument: CVarArg? = nil) -> String {
    let localized = NSLocalizedString(String(describing: key), comment: comment!)
    if let argument = argument {
        return NSString.localizedStringWithFormat(localized as NSString, argument) as String
    }
    return localized
}

/**
 `a` is short for `accessibility` and shortens accessibility label code.
 - parameter argument: Singular and not variadic supported because Swift doesn't have splats.
 */
func a(_ key: Label, _ argument: CVarArg? = nil) -> String {
    return t(key.rawValue, "accessibility", argument)
}

func dispatchAfter(_ duration: TimeInterval, block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: block)
}

class NotificationPayload {

    fileprivate static let key = "payload"

    var userInfo: UserInfo { return [ NotificationPayload.key: self ] }

}

// MARK: - Extensions

extension Bundle {

    static var appName: String? {
        guard let info = Bundle.main.infoDictionary else { return nil }
        return (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String)
    }

}

extension CGRect {

    mutating func constrainInPlace(inside rect: CGRect) {
        if width > rect.width {
            origin.x = rect.midX - width / 2
        } else {
            if minX < rect.minX {
                origin.x = rect.minX
            } else if maxX > rect.maxX {
                origin.x = rect.maxX - width
            }
        }
        if height > rect.height {
            origin.y = rect.midY - height / 2
        } else {
            if minY < rect.minY {
                origin.y = rect.minY
            } else if maxY > rect.maxY {
                origin.y = rect.maxY - height
            }
        }
    }

}

extension Calendar.Component {

    static let dayComponents: Set<Calendar.Component> = [.day, .month, .year]
    static let hourComponents: Set<Calendar.Component> = [.hour, .day, .month, .year]
    static let monthComponents: Set<Calendar.Component> = [.month, .year]

}

extension Date {

    /**
     New date based on this date where everything smaller than the day component is 0.
     `numberOfDays` can be negative to get an earlier date.
     */
    func dayDate(byAddingDays days: Int) -> Date {
        return Calendar.current.date(byAdding: DateComponents(day: days), to: self)!.dayDate
    }

    /**
     New date based on this date where everything smaller than the hour component is 0.
     `numberOfHours` can be negative to get an earlier date.
     */
    func hourDate(byAddingHours hours: Int) -> Date {
        return Calendar.current.date(byAdding: DateComponents(hour: hours), to: self)!.hourDate
    }

    var hasCustomTime: Bool {
        return self != dayDate
    }

    var isLastDayInMonth: Bool {
        let daysRange = Calendar.current.range(of: .day, in: .month, for: self)!
        let daysInMonth = daysRange.upperBound - daysRange.lowerBound
        return Calendar.current.component(.day, from: self) == daysInMonth
    }

    /**
     New date based on this date, combined with `timeDate`'s time components.
     */
    func date(withTime timeDate: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents(Set<Calendar.Component>([.hour, .minute, .second]), from: timeDate)
        return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: components.second!, of: self)!
    }

    /**
     This conversion from a valid `NSDate` to normalized `NSDateComponents` and back is obviously
     safe, hence the forced unwrapping.
     */
    private func flooredDate(with components: Set<Calendar.Component>) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents(components, from: self))!
    }

    /** Clone except everything smaller than the day component is 0. */
    var dayDate: Date { return flooredDate(with: Calendar.Component.dayComponents) }

    /** Clone except everything smaller than the hour component is 0. */
    var hourDate: Date { return flooredDate(with: Calendar.Component.hourComponents) }

    /** Clone except everything smaller than the month component is 0. */
    var monthDate: Date { return flooredDate(with: Calendar.Component.monthComponents) }

}

extension DateFormatter {

    // NOTE: This memory can never be freed as long as app is active. But since every screen
    // requires at least one form of formatting, it's reasonable to always keep this in memory.
    private static var sharedDateFormatter = DateFormatter()

    private static func sharedDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter.sharedDateFormatter
        formatter.dateFormat = format
        return formatter
    }

    static var dayFormatter: DateFormatter { return DateFormatter.sharedDateFormatter(format: "d") }

    static var dateFormatter: DateFormatter { return DateFormatter.sharedDateFormatter(format: "MMMM d, y · EEEE") }

    static var monthFormatter: DateFormatter { return DateFormatter.sharedDateFormatter(format: "MMMM") }

    static var monthDayFormatter: DateFormatter { return DateFormatter.sharedDateFormatter(format: "MMMM d") }

    static var monthYearFormatter: DateFormatter { return DateFormatter.sharedDateFormatter(format: "MMMM y") }

    static var timeFormatter: DateFormatter { return DateFormatter.sharedDateFormatter(format: "h:mm a") }

    static var accessibleDateFormatter: DateFormatter { return DateFormatter.sharedDateFormatter(format: "EEEE, MMMM d, y") }

}

extension Dictionary {

    func notificationUserInfoPayload() -> Any? {
        return ((self as Any) as? UserInfo)?[NotificationPayload.key]
    }
    
}

extension String {

    /**
     Addition. A simple JSON-like debug formatter.
     */
    static func debugDescriptionForGroup(label: String, attributes: [String: String?],
                                         indentLevel: Int = 0) -> String {
        let tab = "\t"
        let outerIndent = String(repeating: tab, count: indentLevel)
        let innerIndent = String(repeating: tab, count: indentLevel + 1)
        return (
            "\(outerIndent)\(label): {\n" +
            attributes.reduce("") { $0 + "\(innerIndent)\($1.0): \($1.1)\n" } +
            "\(outerIndent)}\n"
        )
    }

}

extension UICollectionView {

    /**
     Call this in `viewDidAppear:` and `viewWillDisappear:` if `reverse` is on.
     */
    func updateBackgroundOnAppearance(animated: Bool, reverse: Bool = false) {
        let update = {
            self.backgroundColor = reverse ? UIColor.white : Appearance.collectionViewBackgroundColor
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: update)
        } else {
            update()
        }
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

class ExtendedLabel: UILabel {

    override func drawText(in rect: CGRect) {
        guard let _ = icon else { return super.drawText(in: rect) }
        super.drawText(in: rect.offsetBy(dx: 0, dy: 0.1 * font.pointSize))
    }

}

enum ScrollDirectionX {
    case left, right // content moves: right, left
}

enum ScrollDirectionY {
    case up, down // content moves: down, up
}

struct ScrollDirections {
    var x: ScrollDirectionX
    var y: ScrollDirectionY
}

var scrollViewPreviousContentOffsets = NSMapTable<UIScrollView, NSValue>(
    keyOptions: NSMapTableWeakMemory, valueOptions: NSMapTableStrongMemory
)

extension UIScrollView {

    var currentDirections: ScrollDirections {
        defer {
            scrollViewPreviousContentOffsets.setObject(NSValue(cgPoint: contentOffset), forKey: self)
        }
        guard let previousOffset = scrollViewPreviousContentOffsets.object(forKey: self)?.cgPointValue else {
            return ScrollDirections(x: .right, y: .down)
        }
        return ScrollDirections(
            x: (contentOffset.x < previousOffset.x) ? .left : .right,
            y: (contentOffset.y < previousOffset.y) ? .up : .down
        )
    }

    func tearDownCurrentDirectionsState() {
        scrollViewPreviousContentOffsets.removeObject(forKey: self)
    }

}

extension UIView {

    /**
     Addition. Animates layout constraint changes immediately, with animation and spring options
     that have an app-specific base.
     */
    func animateLayoutChanges(duration: TimeInterval, usingSpring: Bool = true,
                              options: UIViewAnimationOptions, completion: ((Bool) -> Void)?) {
        let animations = { self.layoutIfNeeded() }
        setNeedsUpdateConstraints()
        if usingSpring {
            let (damping, initialVelocity) = Appearance.drawerSpringAnimation
            UIView.animate(
                withDuration: duration, delay: 0,
                usingSpringWithDamping: damping, initialSpringVelocity: initialVelocity,
                options: options, animations: animations, completion: completion
            )
        } else {
            UIView.animate(
                withDuration: duration, delay: 0,
                options: options, animations: animations, completion: completion
            )
        }

    }

    /**
     Addition. Pythagoras distance based durations. `time = distance / rate`
     */
    static func durationForAnimatingBetweenPoints(_ points: (CGPoint, CGPoint),
                                                  withVelocity pointsPerSecond: Double) -> TimeInterval {
        let (a, b) = points
        let distance = Double(sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2)))
        return distance / pointsPerSecond
    }

    /**
     Addition. Sometimes storyboards and xibs aren't suitable.
     */
    func wrap(view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

}
