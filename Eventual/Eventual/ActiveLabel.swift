//
//  ActiveLabel.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class ActiveLabel: UILabel {

    static let actionAttributeName = "ActiveLabelAction"

    weak var actionSender: NSObjectProtocol?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    private func setUp() {
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(detectFragmentTap(_:)))
        )
    }

    @objc private func detectFragmentTap(_ sender: UITapGestureRecognizer) {

    }

}
