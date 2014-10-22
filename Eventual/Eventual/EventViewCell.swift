//
//  EventViewCell.swift
//  Eventual
//
//  Created by Peng Wang on 8/16/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETEventViewCell) class EventViewCell: UICollectionViewCell {
    
    var eventText: String? {
        didSet {
            if self.eventText == oldValue { return }
            let text = self.mainLabel.attributedText
            var mutableText = NSMutableAttributedString(attributedString: text)
            mutableText.replaceCharactersInRange(
                NSRange(location: 0, length: text.length),
                withString: self.eventText!
            )
            self.mainLabel.attributedText = mutableText
        }
    }

    @IBOutlet private var mainLabel: UILabel!
    @IBOutlet private var separator: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.completeSetup()
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.completeSetup()
    }

    private func completeSetup() {
        self.updateTintColorBasedAppearance()
    }

    override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
    override func tintColorDidChange() {
        self.updateTintColorBasedAppearance()
    }

    private func updateTintColorBasedAppearance() {
        self.separator.backgroundColor = self.tintColor
    }
    
}
