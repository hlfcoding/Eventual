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
        return AppearanceManager.defaultManager.colorForIndicatorState(state)
    }

    // Read-only.
    var state: IndicatorState = .Normal {
        didSet {
            self.updateColor()
        }
    }

    var iconTitle: String? { // FIXME: We can't override title.
        get { return self.title }
        set(newValue) {
            self.title = newValue
            self.updateWidth(true)
        }
    }

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setTitleTextAttributes(IconBarButtonItem.baseTitleAttributes, forState: .Normal)
    }

    func toggleState(state: IndicatorState, on: Bool) {
        guard (on && self.state == .Normal) || (!on && self.state == state) else { return }
        self.state = on ? state : .Normal
    }

    // MARK: Private

    private static let baseTitleAttributes: [String: AnyObject] = [
        NSFontAttributeName: UIFont(name: "eventual", size: AppearanceManager.defaultManager.iconBarButtonItemFontSize)!,
        NSForegroundColorAttributeName: AppearanceManager.defaultManager.lightGrayIconColor
    ]

    private func updateColor() {
        guard var attributes = self.titleTextAttributesForState(.Normal) else { return }

        attributes[NSForegroundColorAttributeName] = self.color

        self.setTitleTextAttributes(attributes, forState: .Normal)
    }

    private func updateWidth(forced: Bool = false) {
        guard self.width == 0 || forced,
              let attributes = self.titleTextAttributesForState(.Normal),
                  iconFont = attributes[NSFontAttributeName] as? UIFont
              else { return }

        // Adjust icon layout.
        self.width = round(iconFont.pointSize + 1.15)
    }

}
