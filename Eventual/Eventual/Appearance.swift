//
//  Appearance.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

import HLFMapViewController

struct Appearance {

    static let fontName = "eventual"

    static let lightGrayColor      = UIColor(red: 0.89, green: 0.89, blue: 0.89, alpha: 1)
    static let lightGrayIconColor  = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    static let lightGrayTextColor  = UIColor(red: 0.77, green: 0.77, blue: 0.77, alpha: 1)
    static let darkGrayIconColor   = UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1)
    static let darkGrayTextColor   = UIColor(red: 0.39, green: 0.39, blue: 0.39, alpha: 1)
    static let blueColor           = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
    static let greenColor          = UIColor(red: 0.14, green: 0.74, blue: 0.34, alpha: 1)

    static let collectionViewBackgroundColor = lightGrayColor
    static let drawerSpringAnimation: (damping: CGFloat, initialVelocity: CGFloat) = (0.7, 1)
    static let iconBarButtonItemFontSize: CGFloat = 36

    static var isMinimalismEnabled: Bool { return UserDefaults.standard.bool(forKey: "Minimalism") }

    static func apply() {
        UIView.appearance().tintColor = blueColor

        UITableView.appearance().separatorColor = blueColor
        UITableView.appearance().separatorInset = .zero
    }

    static func configureSearchResult(cell: SearchResultsViewCell, table: UITableView) {
        // NOTE: Regarding custom cell select and highlight background color, it
        // would still not match other cells' select behaviors. The only chance of
        // getting consistency seems to be copying the extensions in CollectionViewTileCell
        // to a SearchResultsViewCell subclass. This would also require references
        // for contentView edge constraints, and allow cell class to be customized.

        var customMargins = cell.contentView.layoutMargins
        customMargins.top = 20
        customMargins.bottom = 20
        cell.contentView.layoutMargins = customMargins
        cell.customTextLabel.font = UIFont.systemFont(ofSize: 17)

        table.rowHeight = 60
    }

}

enum Icon: String {

    case checkCircle = "\u{e602}"
    case clock = "\u{e600}"
    case cross = "\u{e605}"
    case leftArrow = "\u{e604}"
    case mapPin = "\u{e601}"
    case trash = "\u{e603}"

}

enum IndicatorState: Int {

    case normal, active, filled, successful

    func color() -> UIColor {
        switch self {
        case .normal: return Appearance.lightGrayIconColor
        case .active: return Appearance.darkGrayIconColor
        case .filled: return Appearance.blueColor
        case .successful: return Appearance.greenColor
        }
    }

}
