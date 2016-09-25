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
        applyCustomBorder(color: tintColor)
    }

    private func applyCustomBorder(color: UIColor, backgroundColor: UIColor = UIColor(white: 1, alpha: 0.95)) {
        // Temporary appearance changes.
        for view in subviews {
            view.backgroundColor = UIColor.clear
        }
        // Custom bar border color, at the cost of translucency.
        let bgHeight = frame.height + UIApplication.shared.statusBarFrame.height
        let bgImage = createColorImage(color: backgroundColor,
                                       size: CGSize(width: frame.width, height: bgHeight))
        setBackgroundImage(bgImage, for: .default)
        shadowImage = createColorImage(color: color, size: CGSize(width: frame.width, height: 1))
    }

    private func createColorImage(color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        color.setFill()
        path.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

}
