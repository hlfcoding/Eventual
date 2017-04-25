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

    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { context in
            guard !self.isEnabledLocked else { return }
            self.isEnabled = newCollection.verticalSizeClass != .compact
        }
    }

    deinit {
        tearDownKeyboardSync()
    }

    // MARK: - FormFocusState

    var focusState: FormFocusState!

    // Override for waiting dismissal.
    var dismissAfterSaveSegueIdentifier: String? { return nil }

    // Override this default implementation if certain input views should sometimes avoid refocus.
    func shouldRefocus(to view: UIView, from currentView: UIView?) -> Bool {
        return true
    }

    // Override this default implementation if custom blurring or focusing is desired.
    func transitionFocus(to view: UIView?, from currentView: UIView? = nil, completion: (() -> Void)? = nil) {
        currentView?.resignFirstResponder()
        view?.becomeFirstResponder()
        completion?()
    }

    // Override this default implementation if input view has separate dismissal.
    func shouldDismissalSegueWait(for inputView: UIView) -> Bool {
        return inputView is UITextField || inputView is UITextView
    }

    // This must be overridden for dismissal segues to be active.
    func isDismissalSegue(_ identifier: String) -> Bool {
        return false
    }

    func performWaitingSegue(_ identifier: String, completion: @escaping () -> Void) {
        let duration = dismissalWaitDuration(for: focusState.previousInputView)
        dispatchAfter(duration) {
            self.performSegue(withIdentifier: identifier, sender: self)
            completion()
        }
    }

    // Override this default implementation if input view has separate dismissal.
    func dismissalWaitDuration(for inputView: UIView?) -> TimeInterval {
        return 0.3
    }

    // MARK: Overrides

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if focusState.setupWaitingSegue(for: identifier) {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

    // MARK: - FormDataSource

    var dataSource: FormDataSource!

    var formDataObject: NSObject { preconditionFailure("Unimplemented accessor.") }

    var formDataValueToInputView: KeyPathsMap { preconditionFailure("Unimplemented accessor.") }

    func formInfo(for inputView: UIView) -> (name: String, valueKeyPath: String, emptyValue: Any) {
        preconditionFailure("Unimplemented accessor.")
    }

    // Override this for data update handling.
    func formDidChangeDataObject<T>(value: T?, for keyPath: String) {
        if revalidatePerChange {
            validate()
        }
    }

    // Override this for custom value commit handling.
    func formDidCommitValue(for inputView: UIView) {}

    // MARK: - Disabling

    var isEnabled = true {
        didSet {
            toggleEnabled()
        }
    }
    var isEnabledLocked = false

    private func setUpEnabled() {
        initialToolbarHeightConstant = toolbarHeightConstraint.constant
        isEnabled = traitCollection.verticalSizeClass != .compact
    }

    func toggleEnabled() {
        dataSource.forEachInputView { inputView, valueKeyPath in
            switch inputView {
            case let textField as UITextField: textField.isEnabled = self.isEnabled
            case let textView as UITextView: textView.isEditable = self.isEnabled
            case let datePicker as UIDatePicker: datePicker.isEnabled = self.isEnabled
            default: fatalError("Unsupported input-view type.")
            }
        }
        toolbarHeightConstraint.constant = isEnabled ? initialToolbarHeightConstant : 0
        view.setNeedsUpdateConstraints()
    }

    // MARK: - Submission

    @IBAction func completeEditing(_ sender: UIView) {
        do {
            try saveFormData()
            if
                let identifier = dismissAfterSaveSegueIdentifier,
                // Establish waiting segue context if needed.
                shouldPerformSegue(withIdentifier: identifier, sender: self) {
                performSegue(withIdentifier: identifier, sender: self)
            }
            didSaveFormData()
        } catch {
            didReceiveErrorOnFormSave(error)
            toggleErrorPresentation(visible: true)
        }
    }

    func saveFormData() throws {
        preconditionFailure("Unimplemented method.")
    }

    // Override this for custom save success handling.
    func didSaveFormData() {}

    // MARK: - Sync w/ Keyboard

    var keyboardAnimationDuration: TimeInterval?
    @IBOutlet private(set) var toolbar: UIToolbar!
    @IBOutlet private var toolbarBottomEdgeConstraint: NSLayoutConstraint!
    @IBOutlet private var toolbarHeightConstraint: NSLayoutConstraint!
    private var initialToolbarBottomEdgeConstant: CGFloat!
    private var initialToolbarHeightConstant: CGFloat!

    private func setUpKeyboardSync() {
        [Notification.Name.UIKeyboardWillShow, Notification.Name.UIKeyboardWillHide].forEach {
            NotificationCenter.default.addObserver(
                self, selector: #selector(updateOnKeyboardAppearance(_:)),
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
        [Notification.Name.UIKeyboardWillShow, Notification.Name.UIKeyboardWillHide].forEach {
            NotificationCenter.default.removeObserver(self, name: $0, object: nil)
        }
    }

    func updateOnKeyboardAppearance(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as? UserInfo else { return }

        let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]! as! TimeInterval
        keyboardAnimationDuration = duration
        let options = UIViewAnimationOptions(rawValue: userInfo[UIKeyboardAnimationCurveUserInfoKey]! as! UInt)
        var keyboardHeight = 0 as CGFloat

        if notification.name == .UIKeyboardWillShow {
            var frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            frame = view.convert(frame, to: nil)
            keyboardHeight = min(frame.width, frame.height) // Keyboard's height is the smaller dimension.
            willAnimateOnKeyboardAppearance(duration: duration, options: options)
        }

        toolbarBottomEdgeConstraint.constant = keyboardHeight + initialToolbarBottomEdgeConstant
        view.animateLayoutChanges(duration: duration, usingSpring: false, options: options, completion: nil)
    }

    // Override this for additional layout on keyboard appearance.
    func willAnimateOnKeyboardAppearance(duration: TimeInterval, options: UIViewAnimationOptions) {}

    // MARK: - UITextView Placeholder Text

    // Override this for custom placeholder text.
    func placeholder(forTextView textView: UITextView) -> String? {
        return nil
    }

    private var originalTextViewTextColors = NSMapTable<UITextView, UIColor>(keyOptions: [.weakMemory], valueOptions: [.strongMemory])
    // Override these for custom placeholder text color.
    let defaultTextViewTextColor = UIColor.darkText
    var placeholderAlpha: CGFloat = 0.25

    func textColor(forTextView textView: UITextView, placeholderVisible: Bool) -> UIColor {
        if originalTextViewTextColors.object(forKey: textView) == nil, let customColor = textView.textColor {
            originalTextViewTextColors.setObject(customColor, forKey: textView)
        }
        let originalColor = originalTextViewTextColors.object(forKey: textView)
            ?? defaultTextViewTextColor
        return placeholderVisible ? originalColor.withAlphaComponent(placeholderAlpha) : originalColor
    }

    func togglePlaceholder(forTextView textView: UITextView, visible: Bool) {
        guard let placeholder = placeholder(forTextView: textView) else { return }
        defer { textView.textColor = textColor(forTextView: textView, placeholderVisible: visible) }
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
    var validationError: Error?

    lazy var errorViewController: UIAlertController! = {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: t("OK", "button"), style: .default)
            { [unowned self] action in self.toggleErrorPresentation(visible: false) }
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
        } catch {
            validationError = error
        }
    }

    func validateFormData() throws {
        preconditionFailure("Unimplemented method.")
    }

    // Override this for custom save error handling.
    func didReceiveErrorOnFormSave(_ error: Error) {
        guard let error = error as? LocalizedError else { return }
        let description = error.errorDescription ?? t("Unknown Error", "error")
        let failureReason = error.failureReason ?? ""
        let recoverySuggestion = error.recoverySuggestion ?? ""

        errorViewController.title = description.capitalized
            .trimmingCharacters(in: CharacterSet.whitespaces)
            .trimmingCharacters(in: CharacterSet.punctuationCharacters)
        errorViewController.message = "\(failureReason) \(recoverySuggestion)"
            .trimmingCharacters(in: CharacterSet.whitespaces)
    }

    // Override this for custom validation handling.
    func didValidateFormData() {}

    // Override this for custom save error presentation.
    func toggleErrorPresentation(visible: Bool) {
        if visible {
            present(errorViewController, animated: true, completion: nil)
        } else {
            errorViewController.dismiss(animated: true, completion: nil)
        }
    }

}

// MARK: - UITextViewDelegate

extension FormViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        guard !focusState.isShiftingToInputView else { return }
        focusState.shiftInputView(to: textView)

        togglePlaceholder(forTextView: textView, visible: false)
    }

    func textViewDidChange(_ textView: UITextView) {
        dataSource.updateFormData(for: textView, updateDataObject: false)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        dataSource.updateFormData(for: textView, validated: true)
        formDidCommitValue(for: textView)

        togglePlaceholder(forTextView: textView, visible: true)

        guard !focusState.isShiftingToInputView else { return }
        focusState.shiftInputView(to: nil)
    }

}

// MARK: - UIDatePicker Handling

extension FormViewController {

    func datePickerDidChange(_ datePicker: UIDatePicker) {
        dataSource.updateFormData(for: datePicker, validated: true)
    }

    func datePickerDidEndEditing(_ datePicker: UIDatePicker) {
        guard !focusState.isShiftingToInputView else { return }
        focusState.shiftInputView(to: nil)
    }

}
