//
//  EventDetailsView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class EventDetailsView: UIView {

    @IBOutlet private(set) var timeAndLocationLabel: UILabel!

    @IBOutlet private var heightConstraint: NSLayoutConstraint!
    private var initialHeightConstant: CGFloat!

    var event: Event? {
        didSet {
            updateTimeAndLocationLabel(animated: false)
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

        let attributedText = NSMutableAttributedString(string: "")
        guard let emphasisColor = timeAndLocationLabel.tintColor else { preconditionFailure() }

        if event.startDate.hasCustomTime {
            attributedText.append(NSAttributedString(
                string: DateFormatter.timeFormatter.string(from: event.startDate).lowercased(),
                attributes: [ NSForegroundColorAttributeName: emphasisColor ]
            ))
        }

        if event.hasLocation, let locationName = event.location?.components(separatedBy: "\n").first {
            if attributedText.length > 0 {
                attributedText.append(NSAttributedString(string: " at "))
            }
            attributedText.append(NSAttributedString(
                string: locationName,
                attributes: [ NSForegroundColorAttributeName: emphasisColor ]
            ))
        }

        timeAndLocationLabel.attributedText = attributedText

        let visible = attributedText.length > 0
        toggleDetailsDrawer(visible: visible, animated: animated)
    }

}
