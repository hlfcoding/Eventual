//
//  AppearanceManager.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

import HLFMapViewController

class AppearanceManager: NSObject {

    let lightGrayColor      = UIColor(red: 0.89, green: 0.89, blue: 0.89, alpha: 1)
    let lightGrayIconColor  = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    let lightGrayTextColor  = UIColor(red: 0.77, green: 0.77, blue: 0.77, alpha: 1)
    let darkGrayIconColor   = UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1)
    let darkGrayTextColor   = UIColor(red: 0.39, green: 0.39, blue: 0.39, alpha: 1)
    let blueColor           = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
    let greenColor          = UIColor(red: 0.14, green: 0.74, blue: 0.34, alpha: 1)

    let iconBarButtonItemFontSize: CGFloat = 36

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

    func customizeAppearanceOfSearchResults(viewController: SearchResultsViewController,
                                            andCell cell: SearchResultsViewCell)
    {
        // NOTE: Regarding custom cell select and highlight background color, it
        // would still not match other cells' select behaviors. The only chance of
        // getting consistency seems to be copying the extensions in CollectionViewTileCell
        // to a SearchResultsViewCell subclass. This would also require references
        // for contentView edge constraints, and allow cell class to be customized.

        var customMargins = cell.contentView.layoutMargins
        customMargins.top = 20
        customMargins.bottom = 20
        cell.contentView.layoutMargins = customMargins
        viewController.tableView.rowHeight = 60

        cell.customTextLabel.font = UIFont.systemFontOfSize(17)

    }
}
