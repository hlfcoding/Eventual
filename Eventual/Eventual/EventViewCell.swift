//
//  EventViewCell.swift
//  Eventual
//
//  Created by Peng Wang on 8/16/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

class EventViewCell: CollectionViewTileCell {

    @IBOutlet private var mainLabel: UILabel!

    // MARK: - Content

    var eventText: String? {
        didSet {
            if let eventText = self.eventText where eventText != oldValue,
               let text = self.mainLabel.attributedText
            {
                // Convert string to attributed string.
                let mutableText = NSMutableAttributedString(attributedString: text)
                mutableText.replaceCharactersInRange(
                    NSRange(location: 0, length: text.length),
                    withString: eventText
                )
                self.mainLabel.attributedText = mutableText
            }
        }
    }

    // MARK: - Public

    func setAccessibilityLabelsWithIndexPath(indexPath: NSIndexPath) {
        self.accessibilityLabel = NSString(
            format: t(Label.FormatEventCell.rawValue),
            indexPath.item
        ) as String
    }

}
