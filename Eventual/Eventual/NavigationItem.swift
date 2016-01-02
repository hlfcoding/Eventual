//
//  NavigationItem.swift
//  Eventual
//
//  Created by Peng Wang on 10/23/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

class NavigationItem: UINavigationItem {

    override var backBarButtonItem: UIBarButtonItem! {
        get { return self.customBackBarButtonItem }
        set(newValue) {}
    }

    private lazy var customBackBarButtonItem: UIBarButtonItem? = {
        if let iconFont = UIFont(name: FontName, size: AppearanceManager.defaultManager.iconBarButtonItemFontSize)
        {
            let attributes = [ NSFontAttributeName: iconFont ]
            let buttonItem = UIBarButtonItem(
                title: Icon.LeftArrow.rawValue,
                style: .Plain, target: nil, action: nil
            )
            buttonItem.setTitleTextAttributes(attributes, forState: UIControlState.Normal)
            return buttonItem
        }
        return nil
    }()

    override var title: String! {
        didSet {
            if self.title.uppercaseString != self.title {
                self.title = self.title.uppercaseString
            }
        }
    }

    override init(title: String) {
        super.init(title: title)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if let buttonItem = self.leftBarButtonItem where buttonItem.title == Label.NavigationBack.rawValue,
           let iconFont = UIFont(name: FontName, size: AppearanceManager.defaultManager.iconBarButtonItemFontSize)
        {
            buttonItem.setTitleTextAttributes([ NSFontAttributeName: iconFont ], forState: UIControlState.Normal)
            buttonItem.title = Icon.LeftArrow.rawValue
        }
    }

}
