//
//  FormViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class FormViewController: UIViewController, FormDataSourceDelegate, FormFocusStateDelegate {

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        focusState = FormFocusState(delegate: self)
        dataSource = FormDataSource(delegate: self)
        setUpEnabled()
        setUpKeyboardSync()
    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection,
                                                  withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition(nil) { context in
            guard !self.enabledLocked else { return }
            self.enabled = newCollection.verticalSizeClass != .Compact
        }

    }

    deinit {
        tearDownKeyboardSync()
    }

    // MARK: - FormFocusState

    var focusState: FormFocusState!

    // Override for waiting dismissal.
    var dismissAfterSaveSegueIdentifier: String? { return nil }

    var isDebuggingInputState = false

    // Override this default implementation if certain input views should sometimes avoid refocus.
    func shouldRefocusInputView(view: UIView, fromView currentView: UIView?) -> Bool {
        return true
    }

    // Override this default implementation if custom blurring or focusing is desired.
    func transitionFocusFromInputView(source: UIView?, toInputView destination: UIView?,
                                      completionHandler: (() -> Void)?) {
        source?.resignFirstResponder()
        destination?.becomeFirstResponder()
        completionHandler?()
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
    func formDidChangeDataObjectValue<T>(value: T?, atKeyPath keyPath: String) {
        if revalidatePerChange {
            validate()
        }
    }

    // Override this for custom value commit handling.
    func formDidCommitValueForInputView(view: UIView) {}

    // MARK: - Disabling

    var enabled = true {
        didSet {
            toggleEnabled()
        }
    }
    var enabledLocked = false

    private func setUpEnabled() {
        initialToolbarHeightConstant = toolbarHeightConstraint.constant
        enabled = traitCollection.verticalSizeClass != .Compact
    }

    func toggleEnabled() {
        dataSource.forEachInputView { inputView, valueKeyPath in
            switch inputView {
            case let textField as UITextField: textField.enabled = self.enabled
            case let textView as UITextView: textView.editable = self.enabled
            case let datePicker as UIDatePicker: datePicker.enabled = self.enabled
            default: fatalError("Unsupported input-view type.")
            }
        }
        toolbarHeightConstraint.constant = enabled ? initialToolbarHeightConstant : 0
        view.setNeedsUpdateConstraints()
    }

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

    // Override this for custom save success handling.
    func didSaveFormData() {}

    // MARK: - Sync w/ Keyboard

    var keyboardAnimationDuration: NSTimeInterval?
    @IBOutlet private(set) var toolbar: UIToolbar!
    @IBOutlet private var toolbarBottomEdgeConstraint: NSLayoutConstraint!
    @IBOutlet private var toolbarHeightConstraint: NSLayoutConstraint!
    private var initialToolbarBottomEdgeConstant: CGFloat!
    private var initialToolbarHeightConstant: CGFloat!

    private func setUpKeyboardSync() {
        [UIKeyboardWillShowNotification, UIKeyboardWillHideNotification].forEach {
            NSNotificationCenter.defaultCenter().addObserver(
                self, selector: #selector(updateOnKeyboardAppearanceWithNotification(_:)),
                name: $0, object: nil
            )
        }
        // Save initial state.
        initialToolbarBottomEdgeConstant = toolbarBottomEdgeConstraint.constant
        // Style toolbar itself.
        // NOTE: Not the same as setting in IB (which causes artifacts), for some reason.
        toolbar.clipsToBounds = true
    }

    private func tearDownKeyboardSync() {
        [UIKeyboardWillShowNotification, UIKeyboardWillHideNotification].forEach {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: $0, object: nil)
        }
    }

    func updateOnKeyboardAppearanceWithNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? UserInfo else { return }

        let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
        keyboardAnimationDuration = duration
        let options = UIViewAnimationOptions(rawValue: userInfo[UIKeyboardAnimationCurveUserInfoKey]! as! UInt)
        var keyboardHeight = 0 as CGFloat

        if notification.name == UIKeyboardWillShowNotification {
            var frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            frame = view.convertRect(frame, toView: nil)
            keyboardHeight = min(frame.width, frame.height) // Keyboard's height is the smaller dimension.
            willAnimateOnKeyboardAppearance(duration: duration, options: options)
        }

        toolbarBottomEdgeConstraint.constant = keyboardHeight + initialToolbarBottomEdgeConstant
        view.animateLayoutChangesWithDuration(duration, usingSpring: false, options: options, completion: nil)
    }

    // Override this for additional layout on keyboard appearance.
    func willAnimateOnKeyboardAppearance(duration duration: NSTimeInterval, options: UIViewAnimationOptions) {}

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

    lazy var errorViewController: UIAlertController! = {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        alertController.addAction(
            UIAlertAction(title: t("OK", "button"), style: .Default)
            { [unowned self] action in self.toggleErrorPresentation(false) }
        )
        return alertController
    }()

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

    func validateFormData() throws {
        preconditionFailure("Unimplemented method.")
    }

    // Override this for custom save error handling.
    func didReceiveErrorOnFormSave(error: NSError) {
        guard let userInfo = error.userInfo as? ValidationResults else { return }

        let description = userInfo[NSLocalizedDescriptionKey] ?? t("Unknown Error", "error")
        let failureReason = userInfo[NSLocalizedFailureReasonErrorKey] ?? ""
        let recoverySuggestion = userInfo[NSLocalizedRecoverySuggestionErrorKey] ?? ""

        errorViewController.title = description.capitalizedString
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            .stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet())
        errorViewController.message = "\(failureReason) \(recoverySuggestion)"
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    // Override this for custom validation handling.
    func didValidateFormData() {}

    // Override this for custom save error presentation.
    func toggleErrorPresentation(visible: Bool) {
        if visible {
            presentViewController(errorViewController, animated: true, completion: nil)
        } else {
            errorViewController.dismissViewControllerAnimated(true, completion: nil)
        }
    }

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
