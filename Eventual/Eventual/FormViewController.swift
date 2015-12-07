//
//  FormViewController.swift
//  Eventual
//
//  Created by Peng Wang on 10/6/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

enum FormError: ErrorType {
    case BecomeFirstResponderError
    case ResignFirstResponderError
}

class FormFocusState {

    weak var delegate: FormFocusStateDelegate!

    var currentInputView: UIView? {
        didSet {
            if self.delegate.isDebuggingInputState {
                guard let inputName = self.currentInputView?.accessibilityLabel else { return }
                print("Updated currentInputView to \(inputName)")
            }
        }
    }
    var previousInputView: UIView? {
        didSet {
            if self.delegate.isDebuggingInputState {
                guard let inputName = self.previousInputView?.accessibilityLabel else { return }
                print("Updated previousInputView to \(inputName)")
            }
        }
    }
    var isShiftingToInputView = false

    var shouldGuardSegues = true
    private var isWaitingForDismissal = false
    private var waitingSegueIdentifier: String?

    init(delegate: FormFocusStateDelegate) {
        self.delegate = delegate
    }

    func shiftToInputView(view: UIView?, completionHandler: ((FormError?) -> Void)? = nil) {
        guard view !== self.currentInputView && !self.isShiftingToInputView else {
            if self.isShiftingToInputView {
                print("Warning: extra shiftToInputView call for interaction.")
            }
            return
        }
        self.isShiftingToInputView = true
        dispatch_after(0.1) { self.isShiftingToInputView = false }

        var nextView = view
        if nextView == nil {
            if !self.isWaitingForDismissal, let previousInputView = self.previousInputView {
                nextView = previousInputView // Refocus previousInputView.
            }
        }

        let completeShiftInputView: () -> Void = {
            let isRefocusing = nextView == self.previousInputView
            self.previousInputView = isRefocusing ? nil : self.currentInputView

            self.currentInputView = nextView

            if let currentInputView = self.currentInputView {
                self.delegate.focusInputView(currentInputView, completionHandler: completionHandler)
            }

            if self.isWaitingForDismissal { self.performWaitingSegue() }
        }

        if let currentInputView = self.currentInputView {
            self.delegate.blurInputView(currentInputView, withNextView: nextView) { (error) in
                guard error == nil else { completionHandler?(error); return }
                completeShiftInputView()
            }
        } else {
            completeShiftInputView()
        }
    }

    func setupWaitingSegueForIdentifier(identifier: String) -> Bool {
        guard self.shouldGuardSegues && self.delegate.isDismissalSegue(identifier),
              let currentInputView = self.currentInputView
              where self.delegate.shouldDismissalSegueWaitForInputView(currentInputView)
              else { return false }
        self.isWaitingForDismissal = true
        self.waitingSegueIdentifier = identifier
        self.previousInputView = nil
        self.shiftToInputView(nil)
        return true
    }

    private func performWaitingSegue() {
        guard let identifier = self.waitingSegueIdentifier else { return }
        self.isWaitingForDismissal = false
        self.delegate.performWaitingSegueWithIdentifier(identifier) {
            self.waitingSegueIdentifier = nil
        }
    }

}

protocol FormFocusStateDelegate: NSObjectProtocol {

    var isDebuggingInputState: Bool { get set }

    func focusInputView(view: UIView, completionHandler: ((FormError?) -> Void)?)

    func blurInputView(view: UIView, withNextView nextView: UIView?, completionHandler: ((FormError?) -> Void)?)

    func isDismissalSegue(identifier: String) -> Bool

    func performWaitingSegueWithIdentifier(identifier: String, completionHandler: () -> Void)

    func shouldDismissalSegueWaitForInputView(view: UIView) -> Bool

}

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
    
    var revalidatePerChange = true

    var dismissAfterSaveSegueIdentifier: String? { return nil }
    
    var validationError: NSError?
    var isValid: Bool { return self.validationError == nil }

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

    func saveFormData() throws {
        fatalError("Unimplemented method.")
    }
    func validateFormData() throws {
        fatalError("Unimplemented method.")
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
    func toggleErrorPresentation(visible: Bool) {
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
    // Override this default implementation if custom observer adding is desired.
    func setUpFormDataObjectForKVO(options: NSKeyValueObservingOptions = [.Initial, .New, .Old]) {
        for valueKeyPath in self.formDataValueToInputViewKeyPathsMap.keys {
            self.formDataObject.addObserver(self, forKeyPath: valueKeyPath, options: options, context: &sharedObserverContext)
        }
    }
    // Override this default implementation if custom observer removal is desired.
    func tearDownFormDataObjectForKVO() {
        for valueKeyPath in self.formDataValueToInputViewKeyPathsMap.keys {
            self.formDataObject.removeObserver(self, forKeyPath: valueKeyPath, context: &sharedObserverContext)
        }
    }
    func infoForInputView(view: UIView) -> (name: String, valueKeyPath: String, emptyValue: AnyObject) {
        fatalError("Unimplemented accessor.")
    }
    // Override this default implementation if custom data updating is desired.
    func updateFormDataForInputView(view: UIView, validated: Bool = false) {
        let rawValue = self.valueForInputView(view)
        let (_, valueKeyPath, emptyValue) = self.infoForInputView(view)
        var value = rawValue
        // TODO: KVC validation support.
        var isValid = true
        if validated {
            do {
                try (self.formDataObject as! NSObject).validateValue(&value, forKeyPath: valueKeyPath)
            } catch let error as NSError {
                print("Validation error: \(error)")
                isValid = false
            }
        }
        if !validated || isValid {
            self.formDataObject.setValue(value ?? emptyValue, forKeyPath: valueKeyPath)
        }
        if validated {
            if let viewKeyPaths = self.formDataValueToInputViewKeyPathsMap[valueKeyPath] as? [String] {
                // FIXME: This may cause redundant setting.
                for viewKeyPath in viewKeyPaths {
                    if let view = self.valueForKeyPath(viewKeyPath) as? UIView {
                        self.setValue(value ?? emptyValue, forInputView: view)
                    }
                }
            } else {
                self.setValue(value ?? emptyValue, forInputView: view)
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
                if let value: AnyObject = formDataObject.valueForKeyPath(valueKeyPath),
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
        case let textField as UITextField: return textField.text
        case let textView as UITextView: return textView.text
        case let datePicker as UIDatePicker: return datePicker.date
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

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?,
                  change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        guard context == &sharedObserverContext else {
            return super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        let (_, newValue, didChange) = change_result(change)
        guard didChange,
              let formDataObject = self.formDataObject as? NSObject,
              keyPath = keyPath,
              object = object as? NSObject where object === formDataObject
              else { return }
        self.didChangeFormDataValue(newValue, atKeyPath: keyPath)
        if self.revalidatePerChange {
            self.validate()
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
