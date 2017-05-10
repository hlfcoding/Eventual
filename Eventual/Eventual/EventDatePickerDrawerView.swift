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

    private let defaultToggleDuration: TimeInterval = 0.3
    @IBOutlet private var heightConstraint: NSLayoutConstraint!

    func setUp(form: FormViewController) {
        guard !isSetUp else { preconditionFailure("Already set up.") }

        let dayDatePicker = addDatePicker(form: form)
        dayDatePicker.datePickerMode = .date
        self.dayDatePicker = dayDatePicker

        let timeDatePicker = addDatePicker(form: form)
        timeDatePicker.datePickerMode = .time
        timeDatePicker.minuteInterval = 15
        self.timeDatePicker = timeDatePicker
    }

    func toggle(expanded: Bool? = nil,
                customDelay: TimeInterval? = nil,
                customDuration: TimeInterval? = nil,
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
            superview.animateLayoutChanges(duration: duration, options: options, completion: completion)
        }

        if expanded {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: toggle)
        } else {
            toggle()
        }

        isExpanded = expanded
    }

    func toggleToActiveDatePicker() {
        guard let activeDatePicker = activeDatePicker,
            let dayDatePicker = dayDatePicker,
            let timeDatePicker = timeDatePicker
            else { preconditionFailure("Needs setup.") }
        switch activeDatePicker {
        case dayDatePicker:
            toggle(datePicker: dayDatePicker, visible: true)
            toggle(datePicker: timeDatePicker, visible: false)
        case timeDatePicker:
            toggle(datePicker: timeDatePicker, visible: true)
            toggle(datePicker: dayDatePicker, visible: false)
        default: fatalError("Unimplemented date picker.")
        }
    }

    private func addDatePicker(form: FormViewController) -> UIDatePicker {
        let datePicker = UIDatePicker(frame: .zero)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        addSubview(datePicker)
        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: leadingAnchor),
            datePicker.topAnchor.constraint(equalTo: topAnchor),
            datePicker.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        datePicker.addTarget(
            form, action: #selector(FormViewController.datePickerDidChange(_:)),
            for: .valueChanged
        )
        datePicker.addTarget(
            form, action: #selector(FormViewController.datePickerDidEndEditing(_:)),
            for: .editingDidEnd
        )
        return datePicker
    }

    private func toggle(datePicker: UIDatePicker, visible: Bool) {
        datePicker.isHidden = !visible
        datePicker.isEnabled = visible
    }

}
