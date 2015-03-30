//
//  EventViewController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import QuartzCore
import EventKit

// TODO: Rewrite using view controller editing API.

@objc(ETEventViewController) class EventViewController: FormViewController {

    // MARK: State
    
    var event: EKEvent!
    
    private var isDatePickerDrawerExpanded = false
    private var dayIdentifier: String? {
        didSet {
            if self.dayIdentifier != oldValue {
                let shouldToggleVisible = self.dayIdentifier == self.laterIdentifier
                if shouldToggleVisible {
                    self.focusInputView(self.dayDatePicker)
                } else if self.activeDatePicker === self.dayDatePicker {
                    // Only act if our picker's active.
                    self.blurInputView(self.dayDatePicker)
                }
            }
        }
    }
    
    private var isEditingEvent: Bool {
        return self.event != nil && self.event.startDate != nil
    }
    
    // MARK: Subviews & Appearance
    
    @IBOutlet private var dayDatePicker: UIDatePicker!
    @IBOutlet private var timeDatePicker: UIDatePicker!
    private weak var activeDatePicker: UIDatePicker! {
        didSet {
            switch self.activeDatePicker {
            case self.dayDatePicker:
                self.toggleDatePickerActive(true, datePicker: self.dayDatePicker)
                self.toggleDatePickerActive(false, datePicker: self.timeDatePicker)
            case self.timeDatePicker:
                self.toggleDatePickerActive(true, datePicker: self.timeDatePicker)
                self.toggleDatePickerActive(false, datePicker: self.dayDatePicker)
            default: fatalError("Unimplemented date picker.")
            }
        }
    }

    @IBOutlet private var dayLabel: UILabel!
    @IBOutlet private var descriptionView: UITextView!
    @IBOutlet private var descriptionContainerView: UIView!

    @IBOutlet private var editToolbar: UIToolbar!
    @IBOutlet private var timeItem: IconBarButtonItem!
    @IBOutlet private var locationItem: IconBarButtonItem!
    @IBOutlet private var saveItem: IconBarButtonItem!

    @IBOutlet private var dayMenuView: NavigationTitlePickerView!
    
    var descriptionViewFrame: CGRect { return self.descriptionContainerView.frame ?? CGRectZero }
    
    private lazy var errorMessageView: UIAlertView! = {
        let alertView = UIAlertView()
        alertView.delegate = self
        self.acknowledgeErrorButtonIndex = alertView.addButtonWithTitle(t("OK"))
        return alertView
    }()

    private static let DatePickerAppearanceTransitionDuration: NSTimeInterval = 0.3

    // MARK: Constraints
    
    @IBOutlet private var datePickerDrawerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var dayLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var dayLabelTopEdgeConstraint: NSLayoutConstraint!
    private var initialDayLabelHeightConstant: CGFloat!
    private var initialDayLabelTopEdgeConstant: CGFloat!
    @IBOutlet private var toolbarBottomEdgeConstraint: NSLayoutConstraint!
    private var initialToolbarBottomEdgeConstant: CGFloat!

    // MARK: Defines
    
    private var acknowledgeErrorButtonIndex: Int?
    
    private let todayIdentifier: String = t("Today")
    private let tomorrowIdentifier: String = t("Tomorrow")
    private let laterIdentifier: String = t("Later")
    private var orderedIdentifiers: [String] {
        return [self.todayIdentifier, self.tomorrowIdentifier, self.laterIdentifier]
    }

    // MARK: Helpers
    
    private lazy var dayFormatter: NSDateFormatter! = {
        let dayFormatter = NSDateFormatter()
        dayFormatter.dateFormat = "MMMM d, y · EEEE"
        return dayFormatter
    }()

    private lazy var eventManager: EventManager! = {
        return EventManager.defaultManager()
    }()
    private lazy var appearanceManager: AppearanceManager! = {
        return AppearanceManager.defaultManager()
    }()

    // MARK: - Initializers
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setUp()
    }
    override init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }
    
    deinit {
        self.tearDown()
    }
    
    private func setUp() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: Selector("updateOnKeyboardAppearanceWithNotification:"), name: UIKeyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: Selector("updateOnKeyboardAppearanceWithNotification:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    private func tearDown() {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
        self.tearDownDayMenu()
        self.tearDownFormDataObjectForKVO()
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.resetSubviews()
        
        self.setUpNewEvent()
        self.setUpFormDataObjectForKVO(options:.New | .Old)

        self.setUpDayMenu()
        self.setUpDescriptionView()
        self.setUpEditToolbar()

        self.activeDatePicker = self.dayDatePicker
        
        self.updateDescriptionTopMask()
        
        if self.isEditingEvent {
            self.updateInputViewsWithFormDataObject()
        } else {
            self.initializeInputViewsWithFormDataObject()
            self.updateDayIdentifierToItem(self.dayMenuView.visibleItem)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.dayMenuView.alpha = 0.0
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animateWithDuration(0.3) { self.dayMenuView.alpha = 1.0 }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateDescriptionTopMask()
    }
    
    // MARK: - FormViewController
    
    // MARK: Input State
    
    override func focusInputView(view: UIView) -> Bool {
        switch view {
        case self.dayDatePicker, self.timeDatePicker:
            self.activeDatePicker = view as! UIDatePicker
            self.toggleDatePickerDrawerAppearance(visible: true)
            return true
        default:
            return super.focusInputView(view)
        }
    }
    override func blurInputView(view: UIView) -> Bool {
        switch view {
        case self.dayDatePicker, self.timeDatePicker:
            self.toggleDatePickerDrawerAppearance(visible: false) { finished in
                if view === self.timeDatePicker { // Reset to default.
                    self.activeDatePicker = self.dayDatePicker
                }
            }
            return true
        default:
            return super.blurInputView(view)
        }
    }
    
    override func shouldDismissalSegueWaitForInputView(view: UIView) -> Bool {
        let shouldByDefault = super.shouldDismissalSegueWaitForInputView(view)
        return !(view is UIDatePicker) || shouldByDefault
    }
    override func isDismissalSegue(identifier: String) -> Bool {
        let isByDefault = super.isDismissalSegue(identifier)
        return identifier == ETSegue.DismissToMonths.rawValue || isByDefault
    }

    // MARK: Data Handling

    override var dismissAfterSaveSegueIdentifier: String? {
        return ETSegue.DismissToMonths.rawValue
    }

    override func saveFormData() -> (didSave: Bool, error: NSError?) {
        var error: NSError?
        let didSave = self.eventManager.saveEvent(self.event, error: &error)
        return (didSave, error)
    }
    override func validateFormData() -> (isValid: Bool, error: NSError?) {
        var error: NSError?
        let isValid = self.eventManager.validateEvent(self.event, error: &error)
        return (isValid, error)
    }

    override func didChangeFormDataValue(value: AnyObject?, atKeyPath keyPath: String) {
        switch keyPath {
        case "startDate":
            if let startDate = value as? NSDate where startDate != self.timeDatePicker.date {
                self.setValue(startDate, forInputView: self.timeDatePicker)
            }
        default: break
        }
    }
    
    override func didReceiveErrorOnFormSave(error: NSError) {
        if let userInfo = error.userInfo as? [String: String] {
            let description = userInfo[NSLocalizedDescriptionKey] ?? t("Unknown Error")
            let failureReason = userInfo[NSLocalizedFailureReasonErrorKey] ?? ""
            let recoverySuggestion = userInfo[NSLocalizedRecoverySuggestionErrorKey] ?? ""
            self.errorMessageView.title = description.capitalizedString
                .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                .stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet())
            self.errorMessageView.message = "\(failureReason) \(recoverySuggestion)"
                .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        }
    }
    override func didSaveFormData() {}
    override func didValidateFormData() {
        self.saveItem.toggleState(.Successful, on: self.validationResult.isValid)
    }

    override func toggleErrorPresentation(visible: Bool) {
        if visible {
            self.errorMessageView.show()
        } else {
            self.errorMessageView.dismissWithClickedButtonIndex(self.acknowledgeErrorButtonIndex!, animated: true)
        }
    }

    // MARK: Data Binding

    override var formDataObject: AnyObject {
        return self.event
    }
    
    override var formDataValueToInputViewKeyPathsMap: [String: AnyObject] {
        return [
            "title": "descriptionView",
            "startDate": ["dayDatePicker", "timeDatePicker"]
        ]
    }
    
    override func infoForInputView(view: UIView) -> (valueKeyPath: String, emptyValue: AnyObject) {
        let valueKeyPath: String!
        let emptyValue: AnyObject!
        switch view {
        case self.descriptionView:
            valueKeyPath = "title"
            emptyValue = ""
        case self.dayDatePicker, self.timeDatePicker:
            valueKeyPath = "startDate"
            emptyValue = NSDate().dateAsBeginningOfDay()
        default: fatalError("Unimplemented form data key.")
        }
        return (valueKeyPath, emptyValue)
    }

    override func didCommitValueForInputView(view: UIView) {
        switch view {
        case self.dayDatePicker:
            let dayText = self.dayFormatter.stringFromDate(self.dayDatePicker.date)
            self.dayLabel.text = dayText.uppercaseString
        default: break
        }
    }
    
    // MARK: - Actions
    
    @IBAction override func completeEditing(sender: AnyObject) {
        if self.blurInputView(self.descriptionView) {
            if self.descriptionView == self.currentInputView {
                self.shiftCurrentInputViewToView(nil)
            }
        }
        super.completeEditing(sender)
    }
    
    @IBAction func updateDatePicking(sender: AnyObject) {
        if let datePicker = sender as? UIDatePicker {
            self.datePickerDidChange(datePicker)
        }
    }
    
    @IBAction func completeDatePicking(sender: AnyObject) {
        if let datePicker = sender as? UIDatePicker {
            self.datePickerDidEndEditing(datePicker)
        }
    }
    
    @IBAction private func toggleDayPicking(sender: AnyObject) {
        if self.isDatePickerDrawerExpanded {
            // Only blur if picker is active.
            if self.activeDatePicker === self.dayDatePicker {
                self.updateDatePicking(sender)
                self.completeDatePicking(sender) // Blurs.
            } else { // Switch to.
                self.activeDatePicker = self.dayDatePicker
            }
        } else {
            // Switch to and focus.
            self.activeDatePicker = self.dayDatePicker
            self.focusInputView(self.dayDatePicker)
        }
    }

    @IBAction private func toggleTimePicking(sender: AnyObject) {
        if self.isDatePickerDrawerExpanded {
            if self.activeDatePicker === self.timeDatePicker {
                // Only blur if picker is active.
                self.updateDatePicking(self.timeDatePicker)
                self.completeDatePicking(self.timeDatePicker) // Blurs.
            } else { // Switch to.
                self.activeDatePicker = self.timeDatePicker
            }
        } else { // Switch to and focus.
            self.activeDatePicker = self.timeDatePicker
            self.focusInputView(self.timeDatePicker)
        }
    }

    // MARK: - Handlers
    
    func updateOnKeyboardAppearanceWithNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject] {
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
            let options = UIViewAnimationOptions(rawValue: userInfo[UIKeyboardAnimationCurveUserInfoKey]! as! UInt)
            var constant = 0.0 as CGFloat
            if notification.name == UIKeyboardWillShowNotification {
                let frame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
                constant = (frame.size.height > frame.size.width) ? frame.size.width : frame.size.height
                self.toggleDatePickerDrawerAppearance(visible: false, customDuration: duration, customOptions: options)
            }
            self.toolbarBottomEdgeConstraint.constant = constant + self.initialToolbarBottomEdgeConstant
            self.updateLayoutForView(self.editToolbar, withDuration: duration, usingSpring: false, options: options, completion: nil)
        }
    }
    
}

// MARK: - Data

extension EventViewController {
    
    private func setUpNewEvent() {
        if self.isEditingEvent { return }
        self.event = EKEvent(eventStore: self.eventManager.store)
        self.event.startDate = NSDate().dateAsBeginningOfDay()
    }
    
    private func dateFromDayIdentifier(identifier: String) -> NSDate {
        let numberOfDays: Int!
        switch identifier {
        case self.tomorrowIdentifier: numberOfDays = 1
        case self.laterIdentifier: numberOfDays = 2
        default: numberOfDays = 0
        }
        let date = NSDate().dateAsBeginningOfDayFromAddingDays(numberOfDays)
        // Return existing date if fitting when editing.
        if self.isEditingEvent && identifier == self.laterIdentifier {
            let existingDate = self.event.startDate.dateAsBeginningOfDay()
            if existingDate.laterDate(date) == existingDate {
                return existingDate
            }
        }
        return date
    }
    
    private func itemFromDate(date: NSDate) -> UIView {
        let normalizedDate = date.dateAsBeginningOfDay()
        let todayDate = NSDate().dateAsBeginningOfDay()
        let tomorrowDate = NSDate().dateAsBeginningOfDayFromAddingDays(1)
        let index: Int!
        if normalizedDate == todayDate {
            index = find(self.orderedIdentifiers, self.todayIdentifier)!
        } else if normalizedDate == tomorrowDate {
            index = find(self.orderedIdentifiers, self.tomorrowIdentifier)!
        } else {
            index = self.dayMenuView.items.count - 1
        }
        return self.dayMenuView.items[index]
    }
    
    private func updateDayIdentifierToItem(item: UIView?) {
        if let button = item as? UIButton {
            self.dayIdentifier = button.titleForState(.Normal)
        } else if let label = item as? UILabel {
            self.dayIdentifier = label.text
        }
        // Invalidate end date, then update start date.
        self.event.endDate = nil
        let dayDate = self.dateFromDayIdentifier(self.dayIdentifier!)
        self.event.startDate = dayDate
    }
    
    // MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject,
                  change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>)
    {
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        if context != &sharedObserverContext { return }
        let (oldValue: AnyObject?, newValue: AnyObject?, didChange) = change_result(change)
        if !didChange { return }
        if object is EKEvent && keyPath == "startDate",
           let date = newValue as? NSDate
        {
            let dayText = self.dayFormatter.stringFromDate(date)
            self.dayLabel.text = dayText.uppercaseString
        }
    }
    
}

// MARK: - Shared UI

extension EventViewController: UIAlertViewDelegate {
    
    private func updateLayoutForView(view: UIView, withDuration duration: NSTimeInterval, usingSpring: Bool = true,
                 options: UIViewAnimationOptions, completion: ((Bool) -> Void)!)
    {
        let animationOptions = options | .BeginFromCurrentState
        let animations = { view.layoutIfNeeded() }
        let animationCompletion: (Bool) -> Void = { finished in
            if completion != nil {
                completion(finished)
            }
        }
        view.setNeedsUpdateConstraints()
        if usingSpring {
            UIView.animateWithDuration( duration, delay: 0.0,
                usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0,
                options: animationOptions, animations: animations, completion: animationCompletion
            )
        } else {
            UIView.animateWithDuration( duration, delay: 0.0,
                options: animationOptions, animations: animations, completion: animationCompletion
            )
        }
    }
    
    private func resetSubviews() {
        self.dayLabel.text = nil
        self.descriptionView.text = nil
    }
    
    // MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView !== self.errorMessageView { return }
        if let acknowledgeErrorButtonIndex = self.acknowledgeErrorButtonIndex where acknowledgeErrorButtonIndex == buttonIndex {
            self.toggleErrorPresentation(false)
        }
    }
    
}

// MARK: - Day Menu & Date Picker UI

extension EventViewController : NavigationTitleScrollViewDataSource, NavigationTitleScrollViewDelegate {
    
    private func setUpDayMenu() {
        self.dayMenuView.delegate = self
        // Save initial state.
        self.initialDayLabelHeightConstant = self.dayLabelHeightConstraint.constant
        self.initialDayLabelTopEdgeConstant = self.dayLabelTopEdgeConstraint.constant
        // Style day label and menu.
        self.dayLabel.textColor = self.appearanceManager.lightGrayTextColor
        self.dayMenuView.accessibilityLabel = t(ETLabel.EventScreenTitle.rawValue)
        self.dayMenuView.textColor = self.appearanceManager.darkGrayTextColor
        // Provide data source to create items.
        self.dayMenuView.dataSource = self
        // Update if possible. Observe. Commit if needed.
        if self.isEditingEvent {
            self.dayMenuView.visibleItem = self.itemFromDate(self.event.startDate)
        } else {
            self.dayMenuView.updateVisibleItem()
        }
    }
    
    private func tearDownDayMenu() {}
    
    private func toggleDatePickerDrawerAppearance(visible: Bool? = nil,
                                                  customDuration: NSTimeInterval? = nil,
                                                  customOptions: UIViewAnimationOptions? = nil,
                                                  completion: ((Bool) -> Void)? = nil) -> Bool
    {
        let visible = visible ?? !self.isDatePickerDrawerExpanded
        if self.isDatePickerDrawerExpanded == visible { return visible }
        let duration = customDuration ?? EventViewController.DatePickerAppearanceTransitionDuration
        let options = customOptions ?? .CurveEaseInOut
        var delay: NSTimeInterval = 0.0
        func toggle() {
            self.datePickerDrawerHeightConstraint.constant = visible ? self.activeDatePicker.frame.size.height : 1.0
            self.dayLabelHeightConstraint.constant = visible ? 0.0 : self.initialDayLabelHeightConstant
            self.dayLabelTopEdgeConstraint.constant = visible ? 0.0 : self.initialDayLabelTopEdgeConstant
            self.updateLayoutForView(self.view, withDuration: duration, options: options) { finished in
                self.isDatePickerDrawerExpanded = visible
                if !visible {
                    if self.currentInputView === self.activeDatePicker {
                        self.shiftCurrentInputViewToView(nil)
                    }
                    self.performDismissalSegueWithWaitDuration()
                }
                if let completion = completion {
                    completion(finished)
                }
            }
        }
        if visible {
            if self.currentInputView === self.descriptionView { delay = 0.3 }
            self.shiftCurrentInputViewToView(self.activeDatePicker)
            dispatch_after(delay, toggle)
        } else {
            toggle()
        }
        return visible
    }

    private func toggleDatePickerActive(active: Bool, datePicker: UIDatePicker) {
        datePicker.hidden = !active
        datePicker.userInteractionEnabled = active
        if datePicker === self.timeDatePicker {
            self.timeItem.toggleState(.Active, on: active)
        }
    }

    // MARK: NavigationTitleScrollViewDataSource
    
    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int {
        return self.orderedIdentifiers.count
    }
    
    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView? {
        // For each item, decide type, then add and configure.
        let identifier = self.orderedIdentifiers[index]
        let buttonIdentifiers = [self.laterIdentifier]
        let type: ETNavigationTitleItemType = contains(buttonIdentifiers, identifier) ? .Button : .Label
        if let item = self.dayMenuView.newItemOfType(type, withText: identifier),
               itemText = NSString.localizedStringWithFormat(t(ETLabel.FormatDayOption.rawValue), identifier) as? String
        {
            item.accessibilityLabel = itemText
            if identifier == self.laterIdentifier,
               let button = item as? UIButton
            {
                button.addTarget(self, action: "toggleDayPicking:", forControlEvents: .TouchUpInside)
                self.dayDatePicker.minimumDate = self.dateFromDayIdentifier(identifier)
            }
            return item
        }
        return nil
    }

    
    // MARK: NavigationTitleScrollViewDelegate
    
    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, didChangeVisibleItem visibleItem: UIView) {
        self.updateDayIdentifierToItem(visibleItem)
    }
    
}

// MARK: - Description UI

extension EventViewController: UIScrollViewDelegate {
    
    private func setUpDescriptionView() {
        self.descriptionContainerView.layer.mask = CAGradientLayer()
        self.toggleDescriptionTopMask(false)
        self.descriptionView.contentInset = UIEdgeInsets(top: -10.0, left: 0.0, bottom: 0.0, right: 0.0)
        self.descriptionView.scrollIndicatorInsets = UIEdgeInsets(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)
    }

    private func toggleDescriptionTopMask(visible: Bool) {
        let whiteColor: CGColor = UIColor.whiteColor().CGColor // NOTE: We must explicitly type or we get an error.
        let clearColor: CGColor = UIColor.clearColor().CGColor
        let topColor = !visible ? whiteColor : clearColor
        if let maskLayer = self.descriptionContainerView.layer.mask as? CAGradientLayer {
            maskLayer.colors = [topColor, whiteColor, whiteColor, clearColor] as [AnyObject]
        }
    }

    private func updateDescriptionTopMask() {
        let heightRatio = 20.0 / self.descriptionContainerView.frame.size.height
        if let maskLayer = self.descriptionContainerView.layer.mask as? CAGradientLayer {
            maskLayer.locations = [0.0, heightRatio, 1.0 - heightRatio, 1.0]
            maskLayer.frame = self.descriptionContainerView.bounds
        }
    }
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset.y
        if scrollView != self.descriptionView || contentOffset > 44.0 { return }
        let shouldHideTopMask = self.descriptionView.text.isEmpty || contentOffset <= fabs(scrollView.scrollIndicatorInsets.top)
        self.toggleDescriptionTopMask(!shouldHideTopMask)
    }
    
}

// MARK: - Toolbar UI

extension EventViewController {
    
    private func setUpEditToolbar() {
        // Save initial state.
        self.initialToolbarBottomEdgeConstant = self.toolbarBottomEdgeConstraint.constant
        // Style toolbar itself.
        self.editToolbar.clipsToBounds = true
        // Set icons.
        self.timeItem.iconTitle = ETIcon.Clock.rawValue
        self.locationItem.iconTitle = ETIcon.MapPin.rawValue
        self.saveItem.iconTitle = ETIcon.CheckCircle.rawValue
    }

}