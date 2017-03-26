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
    func render(hasInstances value: Bool)

}

protocol EventViewCellRendering {}
extension EventViewCellRendering {

    static func render(cell: EventViewCellRenderable, fromEvent event: Any) {
        let renderedEvent: Event
        if let instances = event as? NSArray {
            renderedEvent = instances.firstObject as! Event
        } else {
            renderedEvent = event as! Event
        }

        let changed = (eventDetails: true,
                       eventText: renderedEvent.title != cell.eventText)

        cell.render(hasInstances: event is NSArray)

        if changed.eventDetails {
            cell.render(eventDetails: renderedEvent)
        }
        if changed.eventText {
            cell.render(eventText: renderedEvent.title)
            cell.eventText = renderedEvent.title

            cell.renderAccessibilityValue(renderedEvent.title as Any?)
        }
    }

    static func teardownRendering(for cell: EventViewCellRenderable) {
        cell.eventText = nil
    }

}

protocol EventViewCellDelegate: NSObjectProtocol {

    func eventViewCell(_ cell: EventViewCell, didToggleInstances visible: Bool)

}

final class EventViewCell: CollectionViewTileCell, EventViewCellRenderable, EventViewCellRendering {

    weak var delegate: EventViewCellDelegate?

    @IBOutlet private(set) var mainLabel: UILabel!
    @IBOutlet private(set) var detailsView: EventDetailsView!
    @IBOutlet private(set) var instancesView: UICollectionView!
    @IBOutlet private(set) var instancesIndicator: UIButton!
    @IBOutlet private(set) var instancesCollapsedHeight: NSLayoutConstraint!

    @IBAction func toggleInstances(_ sender: UIButton) {
        let visible = instancesCollapsedHeight.isActive
        UIApplication.shared.beginIgnoringInteractionEvents()
        var steps: [() -> Void] = []
        steps.append({
            UIView.animate(withDuration: 0.2, animations: { self.instancesIndicator.alpha = 0 })
            { finished in steps[1]() }
        })
        steps.append({
            self.instancesCollapsedHeight.isActive = !visible
            self.delegate?.eventViewCell(self, didToggleInstances: visible)
            UIView.animate(withDuration: 0.2, animations: { self.instancesView.alpha = visible ? 1 : 0 })
            { finished in steps[2]() }
        })
        steps.append({
            UIView.animate(withDuration: 0.2, animations: { self.instancesIndicator.alpha = 1 })
            { finished in steps[3]() }
        })
        steps.append({
            UIApplication.shared.endIgnoringInteractionEvents()
        })
        steps[0]()
    }

    // MARK: - EventViewCellRendering

    var eventText: String?

    func render(eventDetails event: Event) {
        detailsView.event = event
    }

    func render(eventText text: String) {
        mainLabel.text = text
    }

    func render(hasInstances value: Bool) {
        instancesIndicator.isHidden = !value
    }

    // MARK: - CollectionViewTileCell

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !instancesIndicator.isHidden else {
            return super.hitTest(point, with: event)
        }
        let indicatorHitBox = instancesIndicator.frame.insetBy(dx: 0, dy: -20)
        guard indicatorHitBox.contains(point) else {
            return super.hitTest(point, with: event)
        }
        return instancesIndicator
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        detailsView.event = nil
        instancesIndicator.isHidden = true
        instancesCollapsedHeight.isActive = true
        EventViewCell.teardownRendering(for: self)
    }

    override func updateTintColorBasedAppearance() {
        super.updateTintColorBasedAppearance()
        instancesIndicator.backgroundColor = tintColor
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
