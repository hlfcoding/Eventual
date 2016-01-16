//
//  EventDetailsView.swift
//  Eventual
//
//  Created by Peng Wang on 1/16/16.
//  Copyright (c) 2016 Eventual App. All rights reserved.
//

import UIKit
import EventKit

class EventDetailsView: UIView {

    @IBOutlet var timeAndLocationLabel: UILabel!

    @IBOutlet private var heightConstraint: NSLayoutConstraint!
    private var initialHeightConstant: CGFloat!

    var event: EKEvent? {
        didSet {
            self.updateTimeAndLocationLabelAnimated(false)
        }
    }

    static var timeFormatter: NSDateFormatter {
        guard EventDetailsView.sharedTimeFormatter == nil
              else { return EventDetailsView.sharedTimeFormatter! }

        let formatter = NSDateFormatter()
        formatter.dateFormat = "h:mm a"
        EventDetailsView.sharedTimeFormatter = formatter
        return formatter
    }
    private static var sharedTimeFormatter: NSDateFormatter?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setUp()
    }

    private func setUp() {
        self.initialHeightConstant = self.heightConstraint.constant
    }

    func toggleDetailsDrawerAppearance(visible: Bool, animated: Bool) {
        let constant = visible ? self.initialHeightConstant : 0
        self.heightConstraint.constant = constant

        guard animated else { return }
        self.animateLayoutChangesWithDuration(0.3, options: [.CurveEaseInOut], completion: nil)
    }

    func updateTimeAndLocationLabelAnimated(animated: Bool = true) {
        guard let event = self.event else { fatalError("Event required.") }

        let emphasisColor = self.timeAndLocationLabel.tintColor
        let attributedText = NSMutableAttributedString(string: "")

        if event.startDate.hasCustomTime {
            attributedText.appendAttributedString(NSAttributedString(
                string: EventDetailsView.timeFormatter.stringFromDate(event.startDate).lowercaseString,
                attributes: [ NSForegroundColorAttributeName: emphasisColor ]
            ))
        }

        if event.hasLocation,
           let locationName = event.location?.componentsSeparatedByString("\n").first
        {
            if attributedText.length > 0 {
                attributedText.appendAttributedString(NSAttributedString(string: " at "))
            }
            attributedText.appendAttributedString(NSAttributedString(string: locationName,
                attributes: [ NSForegroundColorAttributeName: emphasisColor ]
            ))
        }

        self.timeAndLocationLabel.attributedText = attributedText

        let visible = attributedText.length > 0
        self.toggleDetailsDrawerAppearance(visible, animated: animated)
    }

}
