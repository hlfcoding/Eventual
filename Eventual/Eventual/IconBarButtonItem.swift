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
        guard self.state == nil else { return self.colorForState(state) }
        return self.appearanceManager.lightGrayIconColor
    }
    func colorForState(state: IndicatorState) -> UIColor {
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

    var state: IndicatorState! {
        didSet {
            self.updateColor(oldValue != nil)
        }
    }

    var iconTitle: String? { // FIXME: We can't override title.
        get { return self.title }
        set(newValue) {
            self.title = newValue
            self.updateWidth(true)
        }
    }

    // NOTE: This is needed because there's a stubborn, button-related highlight
    //       animation that seems un-removable.
    let delay: NSTimeInterval = 0.3

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setTitleTextAttributes(IconBarButtonItem.BaseTitleAttributes, forState: .Normal)
        self.state = .Normal
    }

    func toggleState(state: IndicatorState, on: Bool) {
        guard self.state != .Filled || state != .Active else { return }
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
        if var attributes = self.titleTextAttributesForState(.Normal) {
            attributes[NSForegroundColorAttributeName] = self.color
            if delayed {
                dispatch_after(self.delay) {
                    self.setTitleTextAttributes(attributes, forState: .Normal)
                }
            } else {
                self.setTitleTextAttributes(attributes, forState: .Normal)
            }
        }
    }

    private func updateWidth(forced: Bool = false) {
        guard self.width == 0 || forced else { return }
        if let attributes = self.titleTextAttributesForState(.Normal),
               iconFont = attributes[NSFontAttributeName] as? UIFont
        {
            // Adjust icon layout.
            self.width = round(iconFont.pointSize + 1.15)
        }
    }

}
