//
//  FormViewController.swift
//  Eventual
//
//  Created by Peng Wang on 10/6/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

struct FormDataState {

    var revalidatePerChange = true

    var dismissAfterSaveSegueIdentifier: String? { return nil }

    var validationError: NSError?
    var isValid: Bool { return self.validationError == nil }

    func isValidValue(value: AnyObject, forInputView view: UIView) -> Bool {
        return false
    }

}

class FormViewController: UIViewController, FormFocusStateDelegate {

    // MARK: - UIViewController

    override func viewDidLoad() {
        self.focusState = FormFocusState(delegate: self)
        self.setInputAccessibilityLabels()
    }

    // MARK: - FormFocusState

    var focusState: FormFocusState!

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

    // MARK: - Data Handling

    var dismissAfterSaveSegueIdentifier: String? { return nil }
    var isValid: Bool { return self.validationError == nil }
    var revalidatePerChange = true
    var validationError: NSError?

    func initializeInputViewsWithFormDataObject() {
        for valueKeyPath in self.formDataValueToInputViewKeyPathsMap.keys {
            self.updateInputViewWithFormDataValue(valueKeyPath, commit: true)
        }
    }

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

    func changeFormDataValue(value: AnyObject?, atKeyPath keyPath: String) {
        (self.formDataObject as! NSObject).setValue(value, forKeyPath: keyPath)
        self.didChangeFormDataValue(value, atKeyPath: keyPath)
        if self.revalidatePerChange { self.validate() }
    }

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

    func saveFormData() throws {
        fatalError("Unimplemented method.")
    }
    func toggleErrorPresentation(visible: Bool) {
        fatalError("Unimplemented method.")
    }
    func validateFormData() throws {
        fatalError("Unimplemented method.")
    }

    // Override this for data update handling.
    func didChangeFormDataValue(value: AnyObject?, atKeyPath keyPath: String) {}
    // Override this for custom save error handling.
    func didReceiveErrorOnFormSave(error: NSError) {}
    // Override this for custom save success handling.
    func didSaveFormData() {}
    // Override this for custom validation handling.
    func didValidateFormData() {}

    // MARK: - Data Binding

    var formDataObject: AnyObject {
        fatalError("Unimplemented accessor.")
    }
    var formDataValueToInputViewKeyPathsMap: [String: AnyObject] {
        fatalError("Unimplemented accessor.")
    }
    func infoForInputView(view: UIView) -> (name: String, valueKeyPath: String, emptyValue: AnyObject) {
        fatalError("Unimplemented accessor.")
    }
    // Override this default implementation if custom data updating is desired.
    func updateFormDataForInputView(view: UIView, validated: Bool = false) {
        let (_, valueKeyPath, emptyValue) = self.infoForInputView(view)
        var rawValue = self.valueForInputView(view)
        // TODO: KVC validation support.
        var isValid = true
        if validated {
            do {
                try (self.formDataObject as! NSObject).validateValue(&rawValue, forKeyPath: valueKeyPath)
            } catch let error as NSError {
                print("Validation error: \(error)")
                isValid = false
            }
        }
        let newValue = rawValue ?? emptyValue
        if !validated || isValid {
            self.changeFormDataValue(newValue, atKeyPath: valueKeyPath)
        }
        if validated {
            if let viewKeyPaths = self.formDataValueToInputViewKeyPathsMap[valueKeyPath] as? [String] {
                // FIXME: This may cause redundant setting.
                for viewKeyPath in viewKeyPaths {
                    guard let view = self.valueForKeyPath(viewKeyPath) as? UIView else { continue }
                    self.setValue(newValue, forInputView: view)
                }
            } else {
                self.setValue(newValue, forInputView: view)
            }
        }
    }
    // Override this default implementation if custom view updating is desired.
    func updateInputViewsWithFormDataObject(customFormDataObject: AnyObject? = nil) {
        // FIXME: Implement customFormDataObject support.
        for valueKeyPath in self.formDataValueToInputViewKeyPathsMap.keys {
            self.updateInputViewWithFormDataValue(valueKeyPath, commit: true)
        }
    }
    // Override this default implementation if custom value setting is desired.
    func updateInputViewWithFormDataValue(valueKeyPath: String, commit shouldCommit: Bool = false) {
        // Arrays are supported for multiple inputs mapping to same value key-path.
        if let viewKeyPath: AnyObject = self.formDataValueToInputViewKeyPathsMap[valueKeyPath] {
            let viewKeyPaths: [String]
            if let array = viewKeyPath as? [String] {
                viewKeyPaths = array
            } else if let string = viewKeyPath as? String {
                viewKeyPaths = [ string ]
            } else {
                fatalError("Unsupported view key-path type.")
            }
            for viewKeyPath in viewKeyPaths {
                if let value: AnyObject = self.formDataObject.valueForKeyPath(valueKeyPath),
                       view = self.valueForKeyPath(viewKeyPath) as? UIView
                {
                    self.setValue(value, forInputView: view, commit: shouldCommit)
                }
            }
        }
    }
    // Override this default implementation if custom value getting is desired.
    func valueForInputView(view: UIView) -> AnyObject? {
        switch view {
        case let textField as UITextField: return textField.text?.copy()
        case let textView as UITextView: return textView.text?.copy()
        case let datePicker as UIDatePicker: return datePicker.date.copy()
        default: fatalError("Unsupported input-view type")
        }
    }
    // Override this default implementation if custom value setting is desired.
    func setValue(value: AnyObject, forInputView view: UIView, commit shouldCommit: Bool = false) {
        switch view {
        case let textField as UITextField:
            guard let text = value as? String where text != textField.text else { return }
            textField.text = text
        case let textView as UITextView:
            guard let text = value as? String where text != textView.text else { return }
            textView.text = text
        case let datePicker as UIDatePicker:
            guard let date = value as? NSDate where date != datePicker.date else { return }
            datePicker.date = date
        default: fatalError("Unsupported input-view type")
        }
        guard shouldCommit else { return }
        self.didCommitValueForInputView(view)
    }
    // Override this for custom value commit handling.
    func didCommitValueForInputView(view: UIView) {}

    func forEachInputView(block: (inputView: UIView) -> Void) {
        for (_, viewKeyPath) in self.formDataValueToInputViewKeyPathsMap {
            if let viewKeyPaths = viewKeyPath as? [String] {
                for viewKeyPath in viewKeyPaths {
                    guard let view = self.valueForKeyPath(viewKeyPath) as? UIView else { continue }
                    block(inputView: view)
                }
            } else if let viewKeyPath = viewKeyPath as? String,
                          view = self.valueForKeyPath(viewKeyPath) as? UIView
            {
                block(inputView: view)
            }
        }
    }

    func setInputAccessibilityLabels() {
        self.forEachInputView { (inputView) in
            let (name, _, _) = self.infoForInputView(inputView)
            inputView.accessibilityLabel = name
        }
    }

}

// MARK: - UITextViewDelegate

extension FormViewController: UITextViewDelegate {

    func textViewDidBeginEditing(textView: UITextView) {
        guard !self.focusState.isShiftingToInputView else { return }
        self.focusState.shiftToInputView(textView)
    }

    func textViewDidChange(textView: UITextView) {
        self.updateFormDataForInputView(textView)
    }

    func textViewDidEndEditing(textView: UITextView) {
        self.updateFormDataForInputView(textView, validated: true)
        self.didCommitValueForInputView(textView)

        guard !self.focusState.isShiftingToInputView else { return }
        self.focusState.shiftToInputView(nil)
    }

}

// MARK: - UIDatePicker Handling

extension FormViewController {

    func datePickerDidChange(datePicker: UIDatePicker) {
        self.updateFormDataForInputView(datePicker, validated: true)
    }

    func datePickerDidEndEditing(datePicker: UIDatePicker) {
        guard !self.focusState.isShiftingToInputView else { return }
        self.focusState.shiftToInputView(nil)
    }

}
