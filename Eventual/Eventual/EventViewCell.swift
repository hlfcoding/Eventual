//
//  EventViewCell.swift
//  Eventual
//
//  Created by Peng Wang on 8/16/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

class EventViewCell: CollectionViewTileCell {

    static let reuseIdentifier = "Event"
    @IBOutlet var mainLabel: UILabel!

    static let mainLabelFont = UIFont.systemFontOfSize(17.0)
    static let mainLabelLineHeight: CGFloat = 20.0
    static let mainLabelMaxHeight: CGFloat = 3 * EventViewCell.mainLabelLineHeight
    static let mainLabelXMargins: CGFloat = 2 * 20.0

    static let emptyCellHeight: CGFloat = 46.0 // Top and bottom margins (23); 105 with one line.

    static func mainLabelTextRectForText(text: String, cellWidth: CGFloat) -> CGRect {
        let contentWidth = cellWidth - EventViewCell.mainLabelXMargins
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .ByWordWrapping
        return (text as NSString).boundingRectWithSize(
            CGSize(width: contentWidth, height: CGFloat.max),
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
