//
//  Appearance.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

struct Appearance {

    static let fontName = "eventual"

    static let lightGrayColor      = UIColor(red: 0.89, green: 0.89, blue: 0.89, alpha: 1)
    static let lightGrayIconColor  = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    static let lightGrayTextColor  = UIColor(red: 0.77, green: 0.77, blue: 0.77, alpha: 1)
    static let darkGrayIconColor   = UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1)
    static let darkGrayTextColor   = UIColor(red: 0.39, green: 0.39, blue: 0.39, alpha: 1)
    static let blueColor           = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
    static let greenColor          = UIColor(red: 0.14, green: 0.74, blue: 0.34, alpha: 1)

    static let iconBarButtonItemFontSize: CGFloat = 36

    static var minimalismEnabled: Bool { return NSUserDefaults.standardUserDefaults().boolForKey("Minimalism") }

    static func apply() {
        UIView.appearance().tintColor = self.blueColor
        UITableView.appearance().separatorColor = self.blueColor

        UILabel.appearance().backgroundColor = UIColor.clearColor()
        UICollectionReusableView.appearance().backgroundColor = UIColor.clearColor()

        UICollectionView.appearance().backgroundColor = UIColor.whiteColor()
        UICollectionViewCell.appearance().backgroundColor = UIColor.whiteColor()

        UITableView.appearance().separatorInset = UIEdgeInsetsZero
    }

}

enum Icon: String {

    case CheckCircle = "\u{e602}"
    case Clock = "\u{e600}"
    case Cross = "\u{e605}"
    case LeftArrow = "\u{e604}"
    case MapPin = "\u{e601}"
    case Trash = "\u{e603}"
    
}

enum IndicatorState: Int {

    case Normal, Active, Filled, Successful

    func color() -> UIColor {
        switch self {
        case .Normal: return Appearance.lightGrayIconColor
        case .Active: return Appearance.darkGrayIconColor
        case .Filled: return Appearance.blueColor
        case .Successful: return Appearance.greenColor
        }
    }

}
