//
//  NavigationBar.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class NavigationBar: UINavigationBar {

    var customShadow: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        customShadow = UIView(frame: .zero)
        customShadow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(customShadow)
        NSLayoutConstraint.activate([
            customShadow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 1),
            customShadow.leadingAnchor.constraint(equalTo: leadingAnchor),
            customShadow.trailingAnchor.constraint(equalTo: trailingAnchor),
            customShadow.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        customShadow.backgroundColor = tintColor
    }

}

class BackButtonItem: UIBarButtonItem {

    override init() {
        super.init()
        customize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customize()
    }

    private func customize() {
        setTitleTextAttributes([ NSFontAttributeName: Appearance.iconBarButtonItemFont ], for: .normal)
        accessibilityLabel = a(.navigationBack)
        title = Icon.leftArrow.rawValue
    }

}
