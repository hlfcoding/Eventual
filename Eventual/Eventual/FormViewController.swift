//
//  FormViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

enum FormError: ErrorType {

    case BecomeFirstResponderError, ResignFirstResponderError

}

class FormViewController: UIViewController, FormDataSourceDelegate, FormFocusStateDelegate {

    // MARK: - UIViewController

    override func viewDidLoad() {
        focusState = FormFocusState(delegate: self)
        dataSource = FormDataSource(delegate: self)
    }

    // MARK: - FormFocusState

    var focusState: FormFocusState!

    // Override for waiting dismissal.
    var dismissAfterSaveSegueIdentifier: String? { return nil }

    var isDebuggingInputState = false

    // TODO: Use `throws`, but this requires errors that reflect Cocoa API details.
    // Override this default implementation if custom focusing is desired.
    func focusInputView(view: UIView, completionHandler: ((FormError?) -> Void)?) {
        let responder = view as UIResponder
        var error: FormError?
        if !responder.becomeFirstResponder() {
            error = .BecomeFirstResponderError
        }
        completionHandler?(error)
    }

    // TODO: Use `throws`, but this requires errors that reflect Cocoa API details.
    // Override this default implementation if custom blurring is desired.
    func blurInputView(view: UIView, withNextView nextView: UIView?, completionHandler: ((FormError?) -> Void)?) {
        let responder = view as UIResponder
        var error: FormError?
        if !responder.resignFirstResponder() {
            error = .ResignFirstResponderError
        }
        completionHandler?(error)
    }

    // Override this default implementation if certain input views should sometimes avoid refocus.
    func shouldRefocusInputView(view: UIView, fromView currentView: UIView?) -> Bool {
        return true
    }

    // Override this default implementation if input view has separate dismissal.
    func shouldDismissalSegueWaitForInputView(view: UIView) -> Bool {
        return view is UITextField || view is UITextView
    }

    // This must be overridden for dismissal segues to be active.
    func isDismissalSegue(identifier: String) -> Bool {
        return false
    }

    func performWaitingSegueWithIdentifier(identifier: String, completionHandler: () -> Void) {
        let duration = dismissalWaitDurationForInputView(focusState.previousInputView)
        dispatchAfter(duration) {
            self.performSegueWithIdentifier(identifier, sender: self)
            completionHandler()
        }
    }

    // Override this default implementation if input view has separate dismissal.
    func dismissalWaitDurationForInputView(view: UIView?) -> NSTimeInterval {
        return 0.3
    }

    // MARK: Overrides

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if focusState.setupWaitingSegueForIdentifier(identifier) {
            return false
        }
        return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
    }

    // MARK: - FormDataSource

    var dataSource: FormDataSource!

    var formDataObject: NSObject { preconditionFailure("Unimplemented accessor.") }

    var formDataValueToInputView: KeyPathsMap { preconditionFailure("Unimplemented accessor.") }

    func infoForInputView(view: UIView) -> (name: String, valueKeyPath: String, emptyValue: AnyObject) {
        preconditionFailure("Unimplemented accessor.")
    }

    // Override this for data update handling.
    func formDidChangeDataObjectValue(value: AnyObject?, atKeyPath keyPath: String) {
        if revalidatePerChange {
            validate()
        }
    }

    // Override this for custom value commit handling.
    func formDidCommitValueForInputView(view: UIView) {}

    // MARK: - Submission

    @IBAction func completeEditing(sender: UIView) {
        do {
            try saveFormData()
            if
                let identifier = dismissAfterSaveSegueIdentifier
                // Establish waiting segue context if needed.
                where shouldPerformSegueWithIdentifier(identifier, sender: self) {
                performSegueWithIdentifier(identifier, sender: self)
            }
            didSaveFormData()
        } catch let error as NSError {
            didReceiveErrorOnFormSave(error)
            toggleErrorPresentation(true)
        }
    }

    func saveFormData() throws {
        preconditionFailure("Unimplemented method.")
    }

    // Override this for custom save error handling.
    func didReceiveErrorOnFormSave(error: NSError) {}

    // Override this for custom save success handling.
    func didSaveFormData() {}

    // MARK: - UITextView Placeholder Text

    // Override this for custom placeholder text.
    func placeholderForTextView(textView: UITextView) -> String? {
        return nil
    }

    private var originalTextViewTextColors = NSMapTable(keyOptions: .WeakMemory, valueOptions: .StrongMemory)
    // Override these for custom placeholder text color.
    let defaultTextViewTextColor = UIColor.darkTextColor()

    func textColorForTextView(textView: UITextView, placeholderVisible: Bool) -> UIColor {
        if originalTextViewTextColors.objectForKey(textView) == nil, let customColor = textView.textColor {
            originalTextViewTextColors.setObject(customColor, forKey: textView)
        }
        let originalColor = originalTextViewTextColors.objectForKey(textView) as? UIColor
            ?? defaultTextViewTextColor
        return placeholderVisible ? originalColor.colorWithAlphaComponent(0.5) : originalColor
    }

    func togglePlaceholderForTextView(textView: UITextView, visible: Bool) {
        guard let placeholder = placeholderForTextView(textView) else { return }
        defer { textView.textColor = textColorForTextView(textView, placeholderVisible: visible) }
        if visible {
            guard textView.text.isEmpty else { return }
            textView.text = placeholder
        } else {
            guard textView.text == placeholder else { return }
            textView.text = ""
        }
    }

    // MARK: - Validation

    var isValid: Bool { return validationError == nil }
    var revalidatePerChange = true
    var validationError: NSError?

    func validate() {
        defer {
            didValidateFormData()
        }
        do {
            try validateFormData()
            validationError = nil
        } catch let error as NSError {
            validationError = error
        }
    }

    func toggleErrorPresentation(visible: Bool) {
        preconditionFailure("Unimplemented method.")
    }

    func validateFormData() throws {
        preconditionFailure("Unimplemented method.")
    }

    // Override this for custom validation handling.
    func didValidateFormData() {}

}

// MARK: - UITextViewDelegate

extension FormViewController: UITextViewDelegate {

    func textViewDidBeginEditing(textView: UITextView) {
        guard !focusState.isShiftingToInputView else { return }
        focusState.shiftToInputView(textView)

        togglePlaceholderForTextView(textView, visible: false)
    }

    func textViewDidChange(textView: UITextView) {
        dataSource.updateFormDataForInputView(textView, updateDataObject: false)
    }

    func textViewDidEndEditing(textView: UITextView) {
        dataSource.updateFormDataForInputView(textView, validated: true)
        formDidCommitValueForInputView(textView)

        togglePlaceholderForTextView(textView, visible: true)

        guard !focusState.isShiftingToInputView else { return }
        focusState.shiftToInputView(nil)
    }

}

// MARK: - UIDatePicker Handling

extension FormViewController {

    func datePickerDidChange(datePicker: UIDatePicker) {
        dataSource.updateFormDataForInputView(datePicker, validated: true)
    }

    func datePickerDidEndEditing(datePicker: UIDatePicker) {
        guard !focusState.isShiftingToInputView else { return }
        focusState.shiftToInputView(nil)
    }

}
