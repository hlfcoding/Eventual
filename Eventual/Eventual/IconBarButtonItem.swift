//
//  IconBarButtonItem.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class IconBarButtonItem: UIBarButtonItem {

    // Read-only.
    var state: IndicatorState = .normal {
        didSet {
            updateColor()
        }
    }

    var icon: Icon? {
        didSet {
            title = icon?.rawValue
            updateWidth(forced: true)
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
        setTitleTextAttributes(IconBarButtonItem.baseTitleAttributes, for: .normal)
    }

    func toggle(state: IndicatorState, on: Bool) {
        guard (on && self.state == .normal) || (!on && self.state == state) else { return }
        self.state = on ? state : .normal
    }

    // MARK: Private

    private static let baseTitleAttributes: Attributes = [
        NSFontAttributeName: Appearance.iconBarButtonItemFont,
        NSForegroundColorAttributeName: Appearance.lightGrayIconColor,
    ]

    private func updateColor() {
        guard var attributes = titleTextAttributes(for: .normal) else { return }
        attributes[NSForegroundColorAttributeName] = state.color()
        setTitleTextAttributes(attributes, for: .normal)
    }

    private func updateWidth(forced: Bool = false) {
        guard width == 0 || forced,
            let attributes = titleTextAttributes(for: .normal),
            let iconFont = attributes[NSFontAttributeName] as? UIFont
            else { return }

        // Adjust icon layout.
        width = round(iconFont.pointSize + 1.15)
    }

}
