//
//  FormViewController.swift
//  Eventual
//
//  Created by Peng Wang on 10/6/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

struct FormFocusState {

    weak var delegate: FormFocusStateDelegate!

    var currentInputView: UIView? {
        didSet {
            guard self.isDebuggingInputState else { return }
            print(
                "Updated previousInputView to \(self.previousInputView?.accessibilityLabel)" +
                ", currentInputView to \(self.currentInputView?.accessibilityLabel)"
            )
        }
    }
    var previousInputView: UIView?
    var isShiftingCurrentInputView = false

    var isDebuggingInputState = false

    var shouldGuardSegues = true
    private var isAttemptingDismissal = false
    private var waitingSegueIdentifier: String?

    init(delegate: FormFocusStateDelegate) {
        self.delegate = delegate
    }

    mutating func shiftToInputView(view: UIView?) {
        guard view !== self.currentInputView && !self.isShiftingCurrentInputView else {
            if self.isShiftingCurrentInputView {
                print("Warning: extra shiftCurrentInputViewToView call for interaction.")
            }
            return
        }
        self.isShiftingCurrentInputView = true
        dispatch_after(0.1) { self.isShiftingCurrentInputView = false }

        var shouldPerformWaitingSegue = false
        if view == nil {
            if self.reFocusPreviousInputView() {
                return
            }
            if let currentInputView = self.currentInputView {
                shouldPerformWaitingSegue = self.delegate.shouldDismissalSegueWaitForInputView(currentInputView)
            }
        }

        if let currentInputView = self.currentInputView {
            self.delegate.blurInputView(currentInputView, withNextView: view)
        }

        self.currentInputView = view

        if shouldPerformWaitingSegue {
            self.performWaitingSegue()
        }
    }

    private mutating func reFocusPreviousInputView() -> Bool {
        guard !self.isAttemptingDismissal, let previousInputView = self.previousInputView else { return false }
        self.delegate.focusInputView(previousInputView)
        self.previousInputView = nil
        self.currentInputView = previousInputView
        return true
    }

    mutating func setupWaitingSegueForIdentifier(identifier: String) -> Bool {
        guard self.shouldGuardSegues && self.delegate.isDismissalSegue(identifier),
              let _ = self.currentInputView else { return false }
        self.isAttemptingDismissal = true
        self.waitingSegueIdentifier = identifier
        self.previousInputView = nil
        self.shiftToInputView(nil)
        return true
    }

    private mutating func performWaitingSegue() {
        guard let _ = self.waitingSegueIdentifier else { return }
        self.isAttemptingDismissal = false
        self.delegate.performWaitingSegue() {
            self.waitingSegueIdentifier = nil
        }
    }

}

protocol FormFocusStateDelegate: NSObjectProtocol {

    func focusInputView(view: UIView) -> Bool

    func blurInputView(view: UIView, withNextView nextView: UIView?) -> Bool

    func isDismissalSegue(identifier: String) -> Bool

    func performWaitingSegue(completionHandler: () -> Void)

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

class FormViewController: UIViewController {

    // MARK: - Input State
    
    var currentInputView: UIView?
    var previousInputView: UIView?

    var isDebuggingInputState = false
    
    var shouldGuardSegues = true
    private var isAttemptingDismissal = false
    private var waitingSegueIdentifier: String? // Temporarily track the segue that needs to wait.

    // TODO: Use `throws`, but this requires errors that reflect Cocoa API details.
    // Override this default implementation if custom focusing is desired.
    func focusInputView(view: UIView) -> Bool {
        let responder = view as UIResponder
        return responder.becomeFirstResponder()
    }
    // TODO: Use `throws`, but this requires errors that reflect Cocoa API details.
    // Override this default implementation if custom blurring is desired.
    func blurInputView(view: UIView, withNextView nextView: UIView?) -> Bool {
        let responder = view as UIResponder
        return responder.resignFirstResponder()
    }
    // Override this default implementation if input view has separate dismissal.
    func shouldDismissalSegueWaitForInputView(view: UIView) -> Bool {
        return view is UITextField || view is UITextView
    }
    // This must be overridden for dismissal segues to be active.
    func isDismissalSegue(identifier: String) -> Bool {
        return false
    }
    // Override this default implementation if input view has separate dismissal.
    func dismissalWaitDurationForInputView(view: UIView?) -> NSTimeInterval {
        return 0.3
    }

    func initializeInputViewsWithFormDataObject() {
        for valueKeyPath in self.formDataValueToInputViewKeyPathsMap.keys {
            self.updateInputViewWithFormDataValue(valueKeyPath, commit: true)
        }
    }

    var isShiftingCurrentInputView = false
    func shiftCurrentInputViewToView(view: UIView?) {
        guard view !== self.currentInputView && !self.isShiftingCurrentInputView else {
            if self.isShiftingCurrentInputView {
                print("Warning: extra shiftCurrentInputViewToView call for interaction.")
            }
            return
        }
        self.isShiftingCurrentInputView = true
        dispatch_after(0.1) { self.isShiftingCurrentInputView = false }
        // Re-focus previously focused input.
        let shouldRefocus = view == nil && !self.isAttemptingDismissal
        if shouldRefocus, let previousInputView = self.previousInputView {
            self.focusInputView(previousInputView)
            // Update.
            self.currentInputView = previousInputView
            if self.isDebuggingInputState {
                print("Returning currentInputView back to \(previousInputView.accessibilityLabel)")
            }
            return
        }
        // Begin main process:
        let canPerformWaitingSegue = view == nil
        var shouldPerformWaitingSegue = canPerformWaitingSegue
        // Blur currently focused input.
        if let currentInputView = self.currentInputView {
            self.blurInputView(currentInputView, withNextView: view)
            if canPerformWaitingSegue {
                shouldPerformWaitingSegue = self.shouldDismissalSegueWaitForInputView(currentInputView)
            }
        }
        // Update.
        self.previousInputView = self.currentInputView
        self.currentInputView = view
        if self.isDebuggingInputState {
            print(
                "Updated previousInputView to \(self.previousInputView?.accessibilityLabel)" +
                ", currentInputView to \(self.currentInputView?.accessibilityLabel)"
            )
        }
        // Retry any waiting segues.
        if shouldPerformWaitingSegue {
            self.performDismissalSegueWithWaitDurationIfNeeded()
        }
    }

    func performDismissalSegueWithWaitDurationIfNeeded() {
        if let identifier = self.waitingSegueIdentifier {
            self.isAttemptingDismissal = false
            let duration = self.dismissalWaitDurationForInputView(self.previousInputView)
            dispatch_after(duration) {
                self.performSegueWithIdentifier(identifier, sender: self)
                self.waitingSegueIdentifier = nil
            }
        }
    }
    
    // MARK: Overrides
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if self.shouldGuardSegues {
            let should = self.currentInputView == nil
            // Set up waiting segue.
            if !should && self.isDismissalSegue(identifier) {
                self.isAttemptingDismissal = true
                self.waitingSegueIdentifier = identifier
                self.previousInputView = nil
                self.shiftCurrentInputViewToView(nil)
            }
            return should
        }
        return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
    }
    
    // MARK: - Data Handling
    
    var revalidatePerChange = true

    var dismissAfterSaveSegueIdentifier: String? { return nil }
    
    var validationError: NSError?
    var isValid: Bool { return self.validationError == nil }

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
    
    // MARK: Overrides

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

    override func viewDidLoad() {
        super.viewDidLoad()

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
        self.shiftCurrentInputViewToView(textView)
    }

    func textViewDidChange(textView: UITextView) {
        self.updateFormDataForInputView(textView)
    }

    func textViewDidEndEditing(textView: UITextView) {
        self.updateFormDataForInputView(textView, validated: true)
        self.didCommitValueForInputView(textView)
        if self.currentInputView === textView {
            self.shiftCurrentInputViewToView(nil)
        }
    }
    
}

// MARK: - UIDatePicker Handling

extension FormViewController {
    
    func datePickerDidChange(datePicker: UIDatePicker) {
        self.updateFormDataForInputView(datePicker, validated: true)
    }
    
    func datePickerDidEndEditing(datePicker: UIDatePicker) {
        if self.currentInputView === datePicker {
            self.shiftCurrentInputViewToView(nil)
        }
    }
    
}