//
//  FormViewController.swift
//  Eventual
//
//  Created by Peng Wang on 10/6/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETFormViewController) class FormViewController: UIViewController {

    // MARK: - Input State
    
    var currentInputView: UIView?
    var previousInputView: UIView?
    
    var shouldGuardSegues = true
    private var isAttemptingDismissal = false
    private var waitingSegueIdentifier: String? // Temporarily track the segue that needs to wait.
    
    // Override this default implementation if custom focusing is desired.
    func focusInputView(view: UIView) -> Bool {
        let responder = view as UIResponder
        return responder.becomeFirstResponder()
    }
    // Override this default implementation if custom blurring is desired.
    func blurInputView(view: UIView) -> Bool {
        let responder = view as UIResponder
        return responder.resignFirstResponder()
    }
    // Override this default implementation if input view has separate dismissal.
    func shouldDismissalSegueWaitForInputView(view: UIView) -> Bool {
        return view is UITextField || view is UITextView
    }
    // This must be overridden.
    func isDismissalSegue(identifier: String) -> Bool {
        return false
    }
    // Override this default implementation if input view has separate dismissal.
    func dismissalWaitDurationForInputView(view: UIView?) -> NSTimeInterval {
        return 0.3
    }
    
    func shiftCurrentInputViewToView(view: UIView?) {
        // Guard.
        if view == self.currentInputView { return }
        // Re-focus previously focused input.
        let shouldRefocus = (view == nil && self.previousInputView != nil && !self.isAttemptingDismissal)
        if shouldRefocus {
            self.focusInputView(self.previousInputView!)
            // Update.
            self.currentInputView = self.previousInputView
            return
        }
        var canPerformWaitingSegue = view == nil
        var shouldPerformWaitingSegue = canPerformWaitingSegue
        // Blur currently focused input.
        if let currentInputView = self.currentInputView {
            self.blurInputView(currentInputView)
            if canPerformWaitingSegue {
                shouldPerformWaitingSegue = self.shouldDismissalSegueWaitForInputView(currentInputView)
            }
        }
        // Update.
        self.previousInputView = self.currentInputView
        self.currentInputView = view
        // Retry any waiting segues.
        if shouldPerformWaitingSegue {
            self.performDismissalSegueWithWaitDuration()
        }
    }

    func performDismissalSegueWithWaitDuration() {
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
        if (!self.shouldGuardSegues) { return true }
        var should = self.currentInputView == nil
        // Set up waiting segue.
        if !should && self.isDismissalSegue(identifier) {
            self.isAttemptingDismissal = true
            self.waitingSegueIdentifier = identifier
            self.previousInputView = nil
            self.shiftCurrentInputViewToView(nil)
        }
        return should
    }
    
    // MARK: - Data Handling
    
    var dismissAfterSaveSegueIdentifier: String? {
        return nil
    }
    
    var validationResult: (isValid: Bool, error: NSError?) = (false, nil) {
        didSet { self.didValidateFormData() }
    }
    
    @IBAction func completeEditing(sender: AnyObject) {
        let result = self.saveFormData()
        if let error = result.error {
            self.didReceiveErrorOnFormSave(error)
        }
        if !result.didSave {
            self.toggleErrorPresentation(true)
        } else {
            if let identifier = self.dismissAfterSaveSegueIdentifier {
                if self.shouldPerformSegueWithIdentifier(identifier, sender: self) {
                    self.performSegueWithIdentifier(identifier, sender: self)
                }
            }
            self.didSaveFormData()
        }
    }
    
    // This must be overridden.
    func saveFormData() -> (didSave: Bool, error: NSError?) {
        return (false, nil)
    }
    // This must be overridden.
    func validateFormData() -> (isValid: Bool, error: NSError?) {
        return (true, nil)
    }
    // This must be overridden.
    func toggleErrorPresentation(visible: Bool) {}
    // Override this for custom save error handling.
    func didReceiveErrorOnFormSave(error: NSError) {}
    // Override this for custom save success handling.
    func didSaveFormData() {}
    // Override this for custom validation handling.
    func didValidateFormData() {}
    
}