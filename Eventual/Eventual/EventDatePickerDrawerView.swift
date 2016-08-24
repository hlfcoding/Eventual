//
//  EventDatePickerDrawerView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class EventDatePickerDrawerView: UIView {

    // NOTE: This doesn't correlate with picker visibility.
    weak var activeDatePicker: UIDatePicker?

    private(set) var dayDatePicker: UIDatePicker?
    private(set) var timeDatePicker: UIDatePicker?
    private(set) var isExpanded = false
    var isSetUp: Bool { return dayDatePicker != nil && timeDatePicker != nil }

    private let defaultToggleDuration: NSTimeInterval = 0.3
    @IBOutlet private var heightConstraint: NSLayoutConstraint!

    func setUp(form form: FormViewController) {
        guard !isSetUp else { preconditionFailure("Already set up.") }

        let dayDatePicker = addDatePicker(form: form)
        dayDatePicker.datePickerMode = .Date
        self.dayDatePicker = dayDatePicker

        let timeDatePicker = addDatePicker(form: form)
        timeDatePicker.datePickerMode = .Time
        timeDatePicker.minuteInterval = 15
        self.timeDatePicker = timeDatePicker
    }

    func toggle(expanded: Bool? = nil,
                customDelay: NSTimeInterval? = nil,
                customDuration: NSTimeInterval? = nil,
                customOptions: UIViewAnimationOptions? = nil,
                toggleAlongside: ((Bool) -> Void)? = nil,
                completion: ((Bool) -> Void)? = nil) {
        guard let activeDatePicker = activeDatePicker else { preconditionFailure("Needs setup.") }
        let expanded = expanded ?? !isExpanded
        guard expanded != isExpanded else {
            completion?(true)
            return
        }

        let delay = customDelay ?? 0
        let duration = customDuration ?? defaultToggleDuration
        let options = customOptions ?? []
        func toggle() {
            guard let superview = self.superview else { preconditionFailure("Needs to be a subview.") }
            heightConstraint.constant = expanded ? activeDatePicker.frame.height : 1
            toggleAlongside?(expanded)
            superview.animateLayoutChangesWithDuration(duration, options: options, completion: completion)
        }
        if expanded {
            dispatchAfter(delay, block: toggle)
        } else {
            toggle()
        }

        isExpanded = expanded
    }

    func toggleToActiveDatePicker() {
        guard let
            activeDatePicker = activeDatePicker,
            dayDatePicker = dayDatePicker,
            timeDatePicker = timeDatePicker
            else { preconditionFailure("Needs setup.") }
        switch activeDatePicker {
        case dayDatePicker:
            toggleDatePicker(dayDatePicker, visible: true)
            toggleDatePicker(timeDatePicker, visible: false)
        case timeDatePicker:
            toggleDatePicker(timeDatePicker, visible: true)
            toggleDatePicker(dayDatePicker, visible: false)
        default: fatalError("Unimplemented date picker.")
        }
    }

    private func addDatePicker(form form: FormViewController) -> UIDatePicker {
        let datePicker = UIDatePicker(frame: CGRectZero)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        addSubview(datePicker)
        NSLayoutConstraint.activateConstraints([
            datePicker.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
            datePicker.topAnchor.constraintEqualToAnchor(topAnchor),
            datePicker.trailingAnchor.constraintEqualToAnchor(trailingAnchor),
        ])
        datePicker.addTarget(
            form, action: #selector(FormViewController.datePickerDidChange(_:)),
            forControlEvents: [.ValueChanged]
        )
        datePicker.addTarget(
            form, action: #selector(FormViewController.datePickerDidEndEditing(_:)),
            forControlEvents: [.EditingDidEnd]
        )
        return datePicker
    }

    private func toggleDatePicker(datePicker: UIDatePicker, visible: Bool) {
        datePicker.hidden = !visible
        datePicker.enabled = visible
        datePicker.userInteractionEnabled = visible
    }

}
