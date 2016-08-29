//
//  NavigationBar.swift
//  Eventual
//
//  Created by Peng Wang on 8/29/16.
//  Copyright © 2016 Eventual App. All rights reserved.
//

import UIKit

class NavigationBar: UINavigationBar {

    override func tintColorDidChange() {
        super.tintColorDidChange()
        applyCustomBorderColor(tintColor)
    }

    private func applyCustomBorderColor(color: UIColor, backgroundColor: UIColor = UIColor(white: 1, alpha: 0.95)) {
        // Temporary appearance changes.
        for view in subviews {
            view.backgroundColor = UIColor.clearColor()
        }
        // Custom bar border color, at the cost of translucency.
        let bgHeight = frame.height + UIApplication.sharedApplication().statusBarFrame.height
        setBackgroundImage(createColorImage(backgroundColor, size: CGSize(width: frame.width, height: bgHeight)),
                           forBarMetrics: .Default)
        shadowImage = createColorImage(color, size: CGSize(width: frame.width, height: 1))
    }

    private func createColorImage(color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        color.setFill()
        path.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}
