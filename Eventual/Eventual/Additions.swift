//
//  Additions.swift
//  Eventual
//
//  Created by Peng Wang on 7/29/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

extension UINavigationItem {
    
    func et_setUpLeftBarButtonItem() {
        let iconFontSize = AppearanceManager.defaultManager().iconBarButtonItemFontSize
        let attributes = [ NSFontAttributeName: UIFont(name: ETFontName, size: iconFontSize) ]
        self.leftBarButtonItem.setTitleTextAttributes(attributes, forState: UIControlState.Normal)
        self.leftBarButtonItem.title = ETIcon.LeftArrow.toRaw()
        
    }

}