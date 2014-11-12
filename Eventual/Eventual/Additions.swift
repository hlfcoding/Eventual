//
//  Additions.swift
//  Eventual
//
//  Created by Peng Wang on 7/29/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

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
    let didChange = (
        (!(newValue == nil && oldValue == nil) &&
            (newValue != nil || oldValue != nil)) ||
        !(newValue!.isEqual(oldValue))
    )
    return (oldValue, newValue, didChange)
}

func color_image(color: UIColor, #size: CGSize) -> UIImage {
    UIGraphicsBeginImageContext(size)
    let path = UIBezierPath(rect: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
    color.setFill()
    path.fill()
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

func debug_view(view: UIView) {
    view.layer.borderWidth = 1.0
    view.layer.borderColor = UIColor.redColor().CGColor
}