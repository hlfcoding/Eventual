//
//  FormViewController.swift
//  Eventual
//
//  Created by Peng Wang on 10/6/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

class FormViewController: UIViewController,
                          FormDataSourceDelegate, FormFocusStateDelegate
{

    // MARK: - UIViewController

    override func viewDidLoad() {
        self.focusState = FormFocusState(delegate: self)
        self.dataSource = FormDataSource(delegate: self)
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
        let duration = self.dismissalWaitDurationForInputView(self.focusState.previousInputView)
        dispatch_after(duration) {
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
        if self.focusState.setupWaitingSegueForIdentifier(identifier) {
            return false
        }
        return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
    }

    // MARK: - FormDataSource

    var dataSource: FormDataSource!

    var formDataObject: NSObject { fatalError("Unimplemented accessor.") }

    var formDataValueToInputViewKeyPathsMap: [String: AnyObject] { fatalError("Unimplemented accessor.") }
    func infoForInputView(view: UIView) -> (name: String, valueKeyPath: String, emptyValue: AnyObject) { fatalError("Unimplemented accessor.") }

    // Override this for data update handling.
    func formDidChangeDataObjectValue(value: AnyObject?, atKeyPath keyPath: String) {
        if self.revalidatePerChange { self.validate() }
    }
    // Override this for custom value commit handling.
    func formDidCommitValueForInputView(view: UIView) {}

    // MARK: - Submission

    @IBAction func completeEditing(sender: UIView) {
        do {
            try self.saveFormData()
            if let identifier = self.dismissAfterSaveSegueIdentifier
                   // Establish waiting segue context if needed.
                   where self.shouldPerformSegueWithIdentifier(identifier, sender: self)
            {
                self.performSegueWithIdentifier(identifier, sender: self)
            }
            self.didSaveFormData()
        } catch let error as NSError {
            self.didReceiveErrorOnFormSave(error)
            self.toggleErrorPresentation(true)
        }
    }

    func saveFormData() throws {
        fatalError("Unimplemented method.")
    }
    // Override this for custom save error handling.
    func didReceiveErrorOnFormSave(error: NSError) {}
    // Override this for custom save success handling.
    func didSaveFormData() {}

    // MARK: - Validation

    var isValid: Bool { return self.validationError == nil }
    var revalidatePerChange = true
    var validationError: NSError?

    func validate() {
        defer {
            self.didValidateFormData()
        }
        do {
            try self.validateFormData()
            self.validationError = nil
        } catch let error as NSError {
            self.validationError = error
        }
    }

    func toggleErrorPresentation(visible: Bool) { fatalError("Unimplemented method.") }
    func validateFormData() throws { fatalError("Unimplemented method.") }
    // Override this for custom validation handling.
    func didValidateFormData() {}

}

// MARK: - UITextViewDelegate

extension FormViewController: UITextViewDelegate {

    func textViewDidBeginEditing(textView: UITextView) {
        guard !self.focusState.isShiftingToInputView else { return }
        self.focusState.shiftToInputView(textView)
    }

    func textViewDidChange(textView: UITextView) {
        self.dataSource.updateFormDataForInputView(textView, updateDataObject: false)
    }

    func textViewDidEndEditing(textView: UITextView) {
        self.dataSource.updateFormDataForInputView(textView, validated: true)
        self.formDidCommitValueForInputView(textView)

        guard !self.focusState.isShiftingToInputView else { return }
        self.focusState.shiftToInputView(nil)
    }

}

// MARK: - UIDatePicker Handling

extension FormViewController {

    func datePickerDidChange(datePicker: UIDatePicker) {
        self.dataSource.updateFormDataForInputView(datePicker, validated: true)
    }

    func datePickerDidEndEditing(datePicker: UIDatePicker) {
        guard !self.focusState.isShiftingToInputView else { return }
        self.focusState.shiftToInputView(nil)
    }

}
