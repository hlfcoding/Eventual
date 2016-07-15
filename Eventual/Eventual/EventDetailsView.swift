//
//  EventDetailsView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class EventDetailsView: UIView {

    @IBOutlet var timeAndLocationLabel: UILabel!

    @IBOutlet private var heightConstraint: NSLayoutConstraint!
    private var initialHeightConstant: CGFloat!

    var event: Event? {
        didSet { updateTimeAndLocationLabelAnimated(false) }
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

    func toggleDetailsDrawerAppearance(visible: Bool, animated: Bool) {
        let constant = visible ? initialHeightConstant : 0
        heightConstraint.constant = constant
        if animated {
            animateLayoutChangesWithDuration(0.3, options: [], completion: nil)
        } else {
            setNeedsUpdateConstraints()
            layoutIfNeeded()
        }
    }

    func updateTimeAndLocationLabelAnimated(animated: Bool = true) {
        guard let event = event else {
            toggleDetailsDrawerAppearance(false, animated: animated)
            return
        }

        let emphasisColor = timeAndLocationLabel.tintColor
        let attributedText = NSMutableAttributedString(string: "")

        if event.startDate.hasCustomTime {
            attributedText.appendAttributedString(NSAttributedString(
                string: NSDateFormatter.timeFormatter.stringFromDate(event.startDate).lowercaseString,
                attributes: [ NSForegroundColorAttributeName: emphasisColor ]
            ))
        }

        if event.hasLocation, let locationName = event.location?.componentsSeparatedByString("\n").first {
            if attributedText.length > 0 {
                attributedText.appendAttributedString(NSAttributedString(string: " at "))
            }
            attributedText.appendAttributedString(NSAttributedString(
                string: locationName,
                attributes: [ NSForegroundColorAttributeName: emphasisColor ]
            ))
        }

        timeAndLocationLabel.attributedText = attributedText

        let visible = attributedText.length > 0
        toggleDetailsDrawerAppearance(visible, animated: animated)
    }

}
