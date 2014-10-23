//
//  NavigationItem.swift
//  Eventual
//
//  Created by Peng Wang on 10/23/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETNavigationItem) class NavigationItem: UINavigationItem {
   
    override lazy var backBarButtonItem: UIBarButtonItem! = {
        let iconFontSize = AppearanceManager.defaultManager().iconBarButtonItemFontSize
        let attributes = [ NSFontAttributeName: UIFont(name: ETFontName, size: iconFontSize) ]
        let buttonItem = UIBarButtonItem(
            title: ETIcon.LeftArrow.toRaw(),
            style: .Plain, target: nil, action: nil
        )
        buttonItem.setTitleTextAttributes(attributes, forState: UIControlState.Normal)
        return buttonItem
    }()
    
    override var title: String! {
        didSet {
            if self.title.uppercaseString != self.title {
                self.title = self.title.uppercaseString
            }
        }
    }
    
    override init(title: String?) {
        super.init(title: title)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if self.leftBarButtonItem?.title == ETLabel.NavigationBack.toRaw() {
            let iconFontSize = AppearanceManager.defaultManager().iconBarButtonItemFontSize
            let attributes = [ NSFontAttributeName: UIFont(name: ETFontName, size: iconFontSize) ]
            let buttonItem = self.leftBarButtonItem!
            buttonItem.setTitleTextAttributes(attributes, forState: UIControlState.Normal)
            buttonItem.title = ETIcon.LeftArrow.toRaw()
        }
    }
    
}
