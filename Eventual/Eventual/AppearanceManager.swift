//
//  ETAppearanceManager.swift
//  Eventual
//
//  Created by Nest Master on 6/2/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETAppearanceManager) class AppearanceManager: NSObject {
    
    var lightGrayColor: UIColor      = UIColor(red: 0.89, green: 0.89, blue: 0.89, alpha: 1.0)
    var lightGrayIconColor: UIColor  = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
    var lightGrayTextColor: UIColor  = UIColor(red: 0.77, green: 0.77, blue: 0.77, alpha: 1.0)
    var darkGrayTextColor: UIColor   = UIColor(red: 0.39, green: 0.39, blue: 0.39, alpha: 1.0)
    var greenColor: UIColor          = UIColor(red: 0.14, green: 0.74, blue: 0.34, alpha: 1.0)
    
    var iconBarButtonItemFontSize: CGFloat = 36.0
    
    init() {
        super.init()
    }
    
    func applyMainStyle() {
        UILabel.appearance().backgroundColor = UIColor.clearColor()
        // TODO: UIView.appearanceWhenContainedIn -- Not supported.
        UICollectionView.appearance().backgroundColor = UIColor.whiteColor()
        // TODO: UICollectionView.appearanceWhenContainedIn -- Not supported.
        UICollectionViewCell.appearance().backgroundColor = UIColor.whiteColor()
        UICollectionReusableView.appearance().backgroundColor = UIColor.clearColor()
        // TODO: UILabel.appearanceWhenContainedIn -- Not supported.
    }
    
    class func defaultManager() -> AppearanceManager? {
        return (UIApplication.sharedApplication().delegate as AppDelegate).appearanceManager;
    }
    
}
