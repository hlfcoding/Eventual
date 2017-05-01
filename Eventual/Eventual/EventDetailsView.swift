//
//  EventDetailsView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class EventDetailsView: UIView {

    @IBOutlet private(set) var timeAndLocationLabel: ActiveLabel!

    @IBOutlet private var heightConstraint: NSLayoutConstraint!
    private var initialHeightConstant: CGFloat!

    var event: Event? {
        didSet {
            updateTimeAndLocationLabel(animated: false)
        }
    }

    var locationLabelAction: Action? {
        didSet {
            timeAndLocationLabel.isUserInteractionEnabled = true
        }
    }
    var timeLabelAction: Action? {
        didSet {
            timeAndLocationLabel.isUserInteractionEnabled = true
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        preconditionFailure("Can only be initialized from nib.")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initialHeightConstant = heightConstraint.constant
    }

    func toggleDetailsDrawer(visible: Bool, animated: Bool) {
        let constant: CGFloat = visible ? initialHeightConstant : 0
        heightConstraint.constant = constant
        if animated {
            animateLayoutChanges(duration: 0.3, options: [], completion: nil)
        } else {
            setNeedsUpdateConstraints()
            layoutIfNeeded()
        }
    }

    func updateTimeAndLocationLabel(animated: Bool = true) {
        guard let event = event else {
            toggleDetailsDrawer(visible: false, animated: animated)
            return
        }

        let emphasisColor = timeAndLocationLabel.tintColor!
        let attributedText = NSMutableAttributedString()
        let emAttributes: Attributes = [ NSForegroundColorAttributeName: emphasisColor ]

        if event.startDate.hasCustomTime {
            let timeText = DateFormatter.timeFormatter.string(from: event.startDate).lowercased()
            var attributes = emAttributes
            if let selector = timeLabelAction?.rawValue {
                attributes[ActiveLabel.actionAttributeName] = selector
            }
            attributedText.append(NSAttributedString(string: timeText, attributes: attributes))
        }

        if event.hasLocation, let locationName = event.location?.components(separatedBy: "\n").first {
            if attributedText.length > 0 {
                attributedText.append(NSAttributedString(string: " at "))
            }
            var attributes = emAttributes
            if let selector = locationLabelAction?.rawValue {
                attributes[ActiveLabel.actionAttributeName] = selector
            }
            attributedText.append(NSAttributedString(string: locationName, attributes: attributes))
        }

        timeAndLocationLabel.attributedText = attributedText

        let visible = attributedText.length > 0
        toggleDetailsDrawer(visible: visible, animated: animated)
    }

}
