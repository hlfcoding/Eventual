//
//  AppearanceManager.swift
//  Eventual
//
//  Created by Peng Wang on 6/2/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

class AppearanceManager: NSObject {

    let lightGrayColor      = UIColor(red: 0.89, green: 0.89, blue: 0.89, alpha: 1.0)
    let lightGrayIconColor  = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
    let lightGrayTextColor  = UIColor(red: 0.77, green: 0.77, blue: 0.77, alpha: 1.0)
    let darkGrayIconColor   = UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1.0)
    let darkGrayTextColor   = UIColor(red: 0.39, green: 0.39, blue: 0.39, alpha: 1.0)
    let blueColor           = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1.0)
    let greenColor          = UIColor(red: 0.14, green: 0.74, blue: 0.34, alpha: 1.0)

    let iconBarButtonItemFontSize: CGFloat = 36.0

    static var defaultManager: AppearanceManager { return AppDelegate.sharedDelegate.appearanceManager }

    override init() {
        super.init()

        self.applyMainStyle()
    }

    func applyMainStyle() {
        UIView.appearance().tintColor = self.blueColor
        UITableView.appearance().separatorColor = self.blueColor

        UILabel.appearance().backgroundColor = UIColor.clearColor()
        UICollectionReusableView.appearance().backgroundColor = UIColor.clearColor()

        UICollectionView.appearance().backgroundColor = UIColor.whiteColor()
        UICollectionViewCell.appearance().backgroundColor = UIColor.whiteColor()

        NavigationTitlePickerView.appearance().textColor = self.darkGrayTextColor

        UITableView.appearance().separatorInset = UIEdgeInsetsZero
    }

    func colorForIndicatorState(state: IndicatorState) -> UIColor {
        switch state {
        case .Normal: return self.lightGrayIconColor
        case .Active: return self.darkGrayIconColor
        case .Filled: return self.blueColor
        case .Successful: return self.greenColor
        }
    }

}
