//
//  EventViewCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol EventViewCellRenderable: NSObjectProtocol, AccessibleViewCell {

    var eventText: String? { get set }

    func renderEventDetails(event: Event)
    func renderEventText(text: String)

}

protocol EventViewCellRendering {}
extension EventViewCellRendering {

    static func renderCell(cell: EventViewCellRenderable, fromEvent event: Event) {
        let changed = (eventDetails: true,
                       eventText: event.title != cell.eventText)

        if changed.eventDetails {
            cell.renderEventDetails(event)
        }
        if changed.eventText {
            cell.renderEventText(event.title)
            cell.eventText = event.title

            cell.renderAccessibilityValue(event.title)
        }
    }

    static func teardownCellRendering(cell: EventViewCellRenderable) {
        cell.eventText = nil
    }

}

final class EventViewCell: CollectionViewTileCell, EventViewCellRenderable, EventViewCellRendering {

    @IBOutlet private(set) var mainLabel: UILabel!
    @IBOutlet private(set) var detailsView: EventDetailsView!

    // MARK: - EventViewCellRendering

    var eventText: String?

    func renderEventDetails(event: Event) {
        detailsView.event = event
    }

    func renderEventText(text: String) {
        mainLabel.text = text
    }

    // MARK: - CollectionViewTileCell

    override func prepareForReuse() {
        super.prepareForReuse()
        detailsView.event = nil
        EventViewCell.teardownCellRendering(self)
    }

    override func toggleAllBorders(visible: Bool) {
        originalBorderSizes = originalBorderSizes ?? borderSizes
        let size = visible ? borderSize : 0
        borderSizes = UIEdgeInsets(top: size, left: 0, bottom: size, right: 0)
    }

}

/**
 Duplicates the sizes from the storyboard for ultimately estimating cell height. Can additionally
 apply a `sizeClass`. When getting the cell `width` from the tile layout, store that value here.
 */
struct EventViewCellSizes {

    private(set) var mainLabelFontSize: CGFloat = 17
    private(set) var mainLabelLineHeight: CGFloat = 20

    private(set) var emptyCellHeight: CGFloat = 2 * 23 // 105 with one line.
    private(set) var detailsViewHeight: CGFloat = 26

    var width: CGFloat?

    init(sizeClass: UIUserInterfaceSizeClass) {
        switch sizeClass {
        case .Unspecified, .Compact: break
        case .Regular:
            mainLabelFontSize = 20
            mainLabelLineHeight = 24
            emptyCellHeight = 2 * 30
        }
    }

}
