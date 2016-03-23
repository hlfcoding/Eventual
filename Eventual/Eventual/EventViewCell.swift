//
//  EventViewCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class EventViewCell: CollectionViewTileCell {

    @IBOutlet var mainLabel: UILabel!
    @IBOutlet var detailsView: EventDetailsView!

    static func mainLabelTextRectForText(text: String, cellSizes: EventViewCellSizes) -> CGRect
    {
        guard let width = cellSizes.width else { assertionFailure("Requires width."); return CGRectZero }

        let contentWidth = width - cellSizes.mainLabelXMargins
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .ByWordWrapping

        return (text as NSString).boundingRectWithSize(
            CGSize(width: contentWidth, height: CGFloat.max),
            options: [ .UsesLineFragmentOrigin, .UsesFontLeading ],
            attributes: [
                NSFontAttributeName: UIFont.systemFontOfSize(cellSizes.mainLabelFontSize),
                NSParagraphStyleAttributeName: paragraphStyle
            ],
            context: nil
        )
    }

    // MARK: - Content

    var eventText: String? {
        didSet {
            guard
                let eventText = self.eventText where eventText != oldValue,
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

/**
 Duplicates the sizes from the storyboard for ultimately estimating cell height. Can additionally
 apply a `sizeClass`. When getting the cell `width` from the tile layout, store that value here.
 */
struct EventViewCellSizes {

    var mainLabelFontSize: CGFloat = 17.0
    var mainLabelLineHeight: CGFloat = 20.0
    var mainLabelMaxHeight: CGFloat = 3 * 20.0
    var mainLabelXMargins: CGFloat = 2 * 20.0

    var emptyCellHeight: CGFloat = 2 * 23.0 // 105 with one line.
    var detailsViewHeight: CGFloat = 30.0

    var width: CGFloat?

    init(sizeClass: UIUserInterfaceSizeClass) {
        switch sizeClass {
        case .Unspecified: break;
        case .Compact: break;
        case .Regular:
            self.mainLabelFontSize = 20.0
            self.mainLabelLineHeight = 24.0
            self.mainLabelMaxHeight = 3 * 24.0
            self.emptyCellHeight = 2 * 30.0
            self.mainLabelXMargins = 2 * 25.0
        }
    }
    
}
