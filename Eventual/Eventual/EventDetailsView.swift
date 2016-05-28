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
        didSet {
            self.updateTimeAndLocationLabelAnimated(false)
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
        self.initialHeightConstant = self.heightConstraint.constant
    }

    func toggleDetailsDrawerAppearance(visible: Bool, animated: Bool) {
        let constant = visible ? self.initialHeightConstant : 0
        self.heightConstraint.constant = constant

        guard animated else { return }
        self.animateLayoutChangesWithDuration(0.3, options: [], completion: nil)
    }

    func updateTimeAndLocationLabelAnimated(animated: Bool = true) {
        guard let event = self.event else { fatalError("Event required.") }

        let emphasisColor = self.timeAndLocationLabel.tintColor
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

        self.timeAndLocationLabel.attributedText = attributedText

        let visible = attributedText.length > 0
        self.toggleDetailsDrawerAppearance(visible, animated: animated)
    }

}
