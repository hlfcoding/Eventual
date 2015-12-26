//
//  EventViewCell.swift
//  Eventual
//
//  Created by Peng Wang on 8/16/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

class EventViewCell: CollectionViewTileCell {

    @IBOutlet var mainLabel: UILabel!

    static let mainLabelFont = UIFont.systemFontOfSize(17.0)
    static let emptyCellHeight: CGFloat = 47.0 // Top (21) and bottom (25) margins; 75 with one line.

    static func mainLabelTextRectForText(text: String, width: CGFloat) -> CGRect {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2 // * 24 (font leading) = ~29
        paragraphStyle.lineBreakMode = .ByWordWrapping
        return (text as NSString).boundingRectWithSize(
            CGSize(width: width, height: CGFloat.max),
            options: [ .UsesLineFragmentOrigin, .UsesFontLeading ],
            attributes: [
                NSFontAttributeName: EventViewCell.mainLabelFont,
                NSParagraphStyleAttributeName: paragraphStyle
            ],
            context: nil
        )
    }

    // MARK: - Content

    var eventText: String? {
        didSet {
            guard let eventText = self.eventText where eventText != oldValue,
                  let text = self.mainLabel.attributedText
                  else { return }
            // Convert string to attributed string. Attributed string is required for multiple
            // lines.
            let range = NSRange(location: 0, length: text.length)
            let mutableText = NSMutableAttributedString(attributedString: text)
            mutableText.replaceCharactersInRange(range, withString: eventText)
            self.mainLabel.attributedText = mutableText
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
