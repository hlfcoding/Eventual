//
//  IconBarButtonItem.swift
//  Eventual
//
//  Created by Peng Wang on 3/13/15.
//  Copyright (c) 2015 Eventual App. All rights reserved.
//

import UIKit

class IconBarButtonItem: UIBarButtonItem {

    var color: UIColor {
        if let state = self.state {
            return self.colorForState(state)
        }
        return self.appearanceManager.lightGrayIconColor
    }
    func colorForState(state: ETIndicatorState) -> UIColor {
        switch state {
        case .Normal:
            return self.appearanceManager.lightGrayIconColor
        case .Active:
            return self.appearanceManager.darkGrayIconColor
        case .Filled:
            return self.appearanceManager.blueColor
        case .Successful:
            return self.appearanceManager.greenColor
        }
    }

    var state: ETIndicatorState! {
        didSet {
            self.updateColor(delayed: oldValue != nil)
        }
    }

    var iconTitle: String? { // FIXME: We can't override title.
        get { return self.title }
        set(newValue) {
            self.title = newValue
            self.updateWidth(forced: true)
        }
    }

    // NOTE: This is needed because there's a stubborn, button-related highlight
    //       animation that seems un-removable.
    let delay: NSTimeInterval = 0.3

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setTitleTextAttributes(IconBarButtonItem.BaseTitleAttributes, forState: .Normal)
        self.state = .Normal
    }

    func toggleState(state: ETIndicatorState, on: Bool) {
        if self.state == .Filled && state == .Active { return }
        self.state = on ? state : .Normal
    }

    // MARK: Private

    private static let BaseTitleAttributes: [String: AnyObject] = [
        NSFontAttributeName: UIFont(name: "eventual", size: AppearanceManager.defaultManager()!.iconBarButtonItemFontSize)!,
        NSForegroundColorAttributeName: AppearanceManager.defaultManager()!.lightGrayIconColor
    ]

    private var appearanceManager: AppearanceManager {
        return AppearanceManager.defaultManager()!
    }

    private func updateColor(delayed: Bool = true) {
        var attributes = self.titleTextAttributesForState(.Normal)
        attributes[NSForegroundColorAttributeName] = self.color
        if delayed {
            dispatch_after(self.delay) {
                self.setTitleTextAttributes(attributes, forState: .Normal)
            }
        } else {
            self.setTitleTextAttributes(attributes, forState: .Normal)
        }
    }

    private func updateWidth(forced: Bool = false) {
        if self.width > 0.0 && !forced { return }
        var attributes = self.titleTextAttributesForState(.Normal)
        if let iconFont = attributes[NSFontAttributeName] as? UIFont {
            // Adjust icon layout.
            self.width = round(iconFont.pointSize + 1.15)
        }
    }

}
