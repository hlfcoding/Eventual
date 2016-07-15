//
//  IconBarButtonItem.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class IconBarButtonItem: UIBarButtonItem {

    // Read-only.
    var state: IndicatorState = .Normal {
        didSet { updateColor() }
    }

    var iconTitle: String? { // FIXME: We can't override title.
        get { return title }
        set(newValue) {
            title = newValue
            updateWidth(true)
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
        setTitleTextAttributes(IconBarButtonItem.baseTitleAttributes, forState: .Normal)
    }

    func toggleState(state: IndicatorState, on: Bool) {
        guard (on && self.state == .Normal) || (!on && self.state == state) else { return }
        self.state = on ? state : .Normal
    }

    // MARK: Private

    private static let baseTitleAttributes: Attributes = [
        NSFontAttributeName: UIFont(name: "eventual", size: Appearance.iconBarButtonItemFontSize)!,
        NSForegroundColorAttributeName: Appearance.lightGrayIconColor
    ]

    private func updateColor() {
        guard var attributes = titleTextAttributesForState(.Normal) else { return }

        attributes[NSForegroundColorAttributeName] = state.color()

        setTitleTextAttributes(attributes, forState: .Normal)
    }

    private func updateWidth(forced: Bool = false) {
        guard width == 0 || forced,
            let attributes = titleTextAttributesForState(.Normal),
            let iconFont = attributes[NSFontAttributeName] as? UIFont
            else { return }

        // Adjust icon layout.
        width = round(iconFont.pointSize + 1.15)
    }

}
