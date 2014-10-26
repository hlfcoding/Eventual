//
//  EventViewCell.swift
//  Eventual
//
//  Created by Peng Wang on 8/16/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETEventViewCell) class EventViewCell: CollectionViewTileCell {
    
    @IBOutlet private var mainLabel: UILabel!
    
    // MARK: - Content
    
    var eventText: String? {
        didSet {
            if self.eventText == oldValue { return }
            // Convert string to attributed string.
            let text = self.mainLabel.attributedText
            var mutableText = NSMutableAttributedString(attributedString: text)
            mutableText.replaceCharactersInRange(
                NSRange(location: 0, length: text.length),
                withString: self.eventText!
            )
            self.mainLabel.attributedText = mutableText
        }
    }
    
}
