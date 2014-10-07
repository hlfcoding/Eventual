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
        if let buttonItem = self.leftBarButtonItem {
            buttonItem.setTitleTextAttributes(attributes, forState: UIControlState.Normal)
            buttonItem.title = ETIcon.LeftArrow.toRaw()
        }
    }

}

func t(key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

func dispatch_after(duration: NSTimeInterval, block: dispatch_block_t!) {
    let time = Int64(duration * Double(NSEC_PER_SEC))
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time), dispatch_get_main_queue(), block)
}

func change_result(change: [NSObject: AnyObject]!) -> (oldValue: AnyObject?, newValue: AnyObject?, didChange: Bool) {
    let oldValue: AnyObject? = change[NSKeyValueChangeOldKey]
    let newValue: AnyObject? = change[NSKeyValueChangeNewKey]
    let didChange = !(newValue == nil && oldValue == nil) || !(newValue!.isEqual(oldValue))
    return (oldValue, newValue, didChange)
}