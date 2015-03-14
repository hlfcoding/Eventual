//
//  IconBarButtonItem.swift
//  Eventual
//
//  Created by Peng Wang on 3/13/15.
//  Copyright (c) 2015 Eventual App. All rights reserved.
//

import UIKit

@objc(ETIconBarButtonItem) class IconBarButtonItem: UIBarButtonItem {

    var color: UIColor {
        if let state = self.state {
            switch state {
            case .Normal:
                return self.appearanceManager.lightGrayIconColor
            case .Active:
                return self.appearanceManager.darkGrayIconColor
            case .Successful:
                return self.appearanceManager.greenColor
            }
        }
        return self.appearanceManager.lightGrayIconColor
    }

    var state: ETIndicatorState! {
        didSet {
            self.updateColor()
        }
    }

    var iconTitle: String? { // FIXME: We can't override title.
        get { return self.title }
        set(newValue) {
            self.title = newValue
            self.updateWidth(forced: true)
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setTitleTextAttributes(IconBarButtonItem.BaseTitleAttributes, forState: .Normal)
        self.state = .Normal
    }

    func toggleState(state: ETIndicatorState, on: Bool) {
        self.state = on ? state : .Normal
    }

    // MARK: Private

    private static let BaseTitleAttributes: [String: AnyObject] = [
        NSFontAttributeName: UIFont(name: "eventual", size: AppearanceManager.defaultManager()!.iconBarButtonItemFontSize)!
    ]

    private var appearanceManager: AppearanceManager {
        return AppearanceManager.defaultManager()!
    }

    private func updateColor() {
        var attributes = self.titleTextAttributesForState(.Normal)
        attributes[NSForegroundColorAttributeName] = self.color
        self.setTitleTextAttributes(attributes, forState: .Normal)
    }

    private func updateWidth(#forced: Bool) {
        if self.width > 0.0 && !forced { return }
        var attributes = self.titleTextAttributesForState(.Normal)
        if let iconFont = attributes[NSFontAttributeName] as? UIFont {
            // Adjust icon layout.
            self.width = round(iconFont.pointSize + 1.15)
        }
    }

}
