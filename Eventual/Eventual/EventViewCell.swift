//
//  EventViewCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol EventViewCellRenderable: NSObjectProtocol, AccessibleViewCell {

    var eventText: String? { get set }

    func render(eventDetails event: Event)
    func render(eventText text: String)

}

protocol EventViewCellRendering {}
extension EventViewCellRendering {

    static func render(cell: EventViewCellRenderable, fromEvent event: Event) {
        let changed = (eventDetails: true,
                       eventText: event.title != cell.eventText)

        if changed.eventDetails {
            cell.render(eventDetails: event)
        }
        if changed.eventText {
            cell.render(eventText: event.title)
            cell.eventText = event.title

            cell.renderAccessibilityValue(event.title as Any?)
        }
    }

    static func teardownRendering(for cell: EventViewCellRenderable) {
        cell.eventText = nil
    }

}

final class EventViewCell: CollectionViewTileCell, EventViewCellRenderable, EventViewCellRendering {

    @IBOutlet private(set) var mainLabel: UILabel!
    @IBOutlet private(set) var detailsView: EventDetailsView!

    // MARK: - EventViewCellRendering

    var eventText: String?

    func render(eventDetails event: Event) {
        detailsView.event = event
    }

    func render(eventText text: String) {
        mainLabel.text = text
    }

    // MARK: - CollectionViewTileCell

    override func prepareForReuse() {
        super.prepareForReuse()
        detailsView.event = nil
        EventViewCell.teardownRendering(for: self)
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
        case .unspecified, .compact: break
        case .regular:
            mainLabelFontSize = 20
            mainLabelLineHeight = 24
            emptyCellHeight = 2 * 30
        }
    }

}
