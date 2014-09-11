//
//  EventViewController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit
import QuartzCore
import EventKit

// TODO: Rewrite using view controller editing API.

private var observerContext = 0

@objc(ETEventViewController) class EventViewController: UIViewController, UITextViewDelegate {

    // MARK: State
    
    var event: EKEvent!
    private var isDataValid: Bool = false {
        didSet {
            self.updateSaveBarButtonItem()
        }
    }
    private var saveError: NSError? {
        didSet {
            if self.saveError == oldValue || self.saveError == nil { return }
            if let userInfo = self.saveError!.userInfo as? [String: String] {
                self.errorMessageView.title = userInfo[NSLocalizedDescriptionKey]!.capitalizedString
                    .stringByReplacingOccurrencesOfString(". ", withString: "")
                self.errorMessageView.message = userInfo[NSLocalizedFailureReasonErrorKey]!
                    .stringByAppendingString(userInfo[NSLocalizedRecoverySuggestionErrorKey]!)
            }
        }
    }
    
    private var isAttemptingDismissal = false
    private var isDatePickerVisible = false
    private var currentInputView: UIView?
    private var previousInputView: UIView?
    private var waitingSegueIdentifier: String?
    private var dayIdentifier: String? {
        didSet {
            if self.dayIdentifier != oldValue {
                self.toggleDatePickerDrawerAppearance(self.dayIdentifier == self.laterIdentifier)
            }
        }
    }
    
    // MARK: Subviews & Appearance
    
    @IBOutlet private var datePicker: UIDatePicker!
    @IBOutlet private var dayLabel: UILabel!
    @IBOutlet private var descriptionView: UITextView!
    @IBOutlet private var descriptionContainerView: UIView!
    @IBOutlet private var editToolbar: UIToolbar!
    @IBOutlet private var timeItem: UIBarButtonItem!
    @IBOutlet private var locationItem: UIBarButtonItem!
    @IBOutlet private var saveItem: UIBarButtonItem!
    @IBOutlet private var dayMenuView: NavigationTitleScrollView!
    
    private var laterItem: UIButton!
    
    private lazy var errorMessageView: UIAlertView! = {
        let alertView = UIAlertView()
        alertView.delegate = self
        self.acknowledgeErrorButtonIndex = alertView.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
        return alertView
    }()

    private let DatePickerAppearanceTransitionDuration: NSTimeInterval = 0.3
    private let BaseEditToolbarIconTitleAttributes: [String: AnyObject] = [
        NSFontAttributeName: UIFont(name: "eventual", size: AppearanceManager.defaultManager().iconBarButtonItemFontSize)
    ]

    // MARK: Constraints
    
    @IBOutlet private var datePickerDrawerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var toolbarBottomEdgeConstraint: NSLayoutConstraint!
    private var initialToolbarBottomEdgeConstant: CGFloat!

    // MARK: Defines
    
    private let observedEventKeyPaths = [ "title", "startDate" ]
    
    private var acknowledgeErrorButtonIndex: Int?
    
    private var todayIdentifier: String!
    private var tomorrowIdentifier: String!
    private var laterIdentifier: String!

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
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setUp()
    }
    required init(coder aDecoder: NSCoder) {
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
        self.tearDownEvent()
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.resetSubviews()
        
        self.setUpNewEvent()
        self.setUpDayMenu()
        self.setUpDescriptionView()
        self.setUpEditToolbar()
        
        self.updateDayIdentifierToItem(self.dayMenuView.visibleItem)
        self.updateDescriptionTopMask()
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
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject!) -> Bool {
        var should = self.currentInputView == nil
        self.isAttemptingDismissal = identifier == ETSegue.DismissToMonths.toRaw()
        if !should {
            self.waitingSegueIdentifier = identifier
            self.previousInputView = nil
            self.shiftCurrentInputViewToView(nil)
        }
        return should
    }
    
    // MARK: Actions
    
    @IBAction private func completeEditing(sender: AnyObject) {
        if self.descriptionView.isFirstResponder() {
            self.descriptionView.resignFirstResponder()
            if self.currentInputView == self.descriptionView {
                self.shiftCurrentInputViewToView(nil)
            }
        }
        self.saveData()
    }
    
    @IBAction private func updateDatePicking(sender: AnyObject) {
        var value: AnyObject? = self.datePicker.date
        var error: NSError?
        if self.event.validateValue(&value, forKey: "stateDate", error: &error) {
            self.event.startDate = value as NSDate!
        }
        self.datePicker.date = value as NSDate!
    }
    
    @IBAction private func completeDatePicking(sender: AnyObject) {
        if self.currentInputView == self.datePicker {
            self.shiftCurrentInputViewToView(nil)
        }
    }
    
    @IBAction private func toggleDatePicking(sender: AnyObject) {
        let didPickDate = self.isDatePickerVisible
        if didPickDate {
            self.updateDatePicking(sender)
            self.completeDatePicking(sender)
        } else {
            self.toggleDatePickerDrawerAppearance(true)
        }
    }
    
    // MARK: Handlers
    
    func updateOnKeyboardAppearanceWithNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject] {
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]! as NSTimeInterval
            let options = UIViewAnimationOptions.fromRaw(userInfo[UIKeyboardAnimationCurveUserInfoKey]! as UInt)
            var constant = 0.0 as CGFloat
            if notification.name == UIKeyboardWillShowNotification {
                let frame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as NSValue).CGRectValue()
                constant = (frame.size.height > frame.size.width) ? frame.size.width : frame.size.height
            }
            self.toolbarBottomEdgeConstraint.constant = constant + self.initialToolbarBottomEdgeConstant
            // TODO: Flawless animation sync using inputAccessoryView.
            self.editToolbar.setNeedsUpdateConstraints()
            self.updateLayoutForView(self.editToolbar, withDuration: duration, usingSpring: false, options: options!, completion: nil)
        }
    }
    
}

// MARK: - Data

extension EventViewController {
    
    private func setUpEvent(options: NSKeyValueObservingOptions = .Initial | .New | .Old) {
        for keyPath in self.observedEventKeyPaths {
            self.event.addObserver(self, forKeyPath: keyPath, options: options, context: &observerContext)
        }
    }
    private func setUpNewEvent() {
        if self.event != nil { return }
        self.event = EKEvent(eventStore: self.eventManager.store)
        self.setUpEvent(options:.New | .Old)
    }
    
    private func tearDownEvent() {
        for keyPath in self.observedEventKeyPaths {
            self.event.removeObserver(self, forKeyPath: keyPath, context: &observerContext)
        }
    }
    
    private func saveData() {
        var error: NSError?
        let didSave = self.eventManager.saveEvent(self.event, error: &error)
        if let saveError = error {
            self.saveError = saveError
        }
        let identifier = ETSegue.DismissToMonths.toRaw()
        if !didSave {
            self.toggleErrorMessage(true)
        } else if self.shouldPerformSegueWithIdentifier(identifier, sender: self) {
            self.performSegueWithIdentifier(identifier, sender: self)
        }
    }
    
    private func validateData() {
        var error: NSError?
        self.isDataValid = self.eventManager.validateEvent(self.event, error: &error)
    }
    
    private func dateFromDayIdentifier(identifier: String) -> NSDate {
        var numberOfDays: Int = 0;
        switch identifier {
        case self.tomorrowIdentifier:
            numberOfDays = 1
        case self.laterIdentifier:
            numberOfDays = 2
        default:
            break
        }
        let date = NSDate.dateFromAddingDays(numberOfDays, toDate: NSDate.date())
        return date
    }
    
    private func updateDayIdentifierToItem(item: UIView?) {
        if let button = item as? UIButton {
            self.dayIdentifier = button.titleForState(.Normal)
        } else if let label = item as? UILabel {
            self.dayIdentifier = label.text
        } else {
            return
        }
        let dayDate = self.dateFromDayIdentifier(self.dayIdentifier!)
        self.event.startDate = dayDate
    }
    
    // MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!,
                  change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<()>)
    {
        if context != &observerContext {
            return super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        let previousValue: AnyObject? = change[NSKeyValueChangeOldKey]
        let value: AnyObject? = change[NSKeyValueChangeNewKey]
        let didChange = !(value == nil && previousValue == nil) || !(value!.isEqual(previousValue)) // FIXME: Sigh.
        if let view = object as? NavigationTitleScrollView {
            if view == self.dayMenuView && didChange && keyPath == "visibleItem" {
                self.updateDayIdentifierToItem(value! as? UIView)
            }
        } else if let event = object as? EKEvent {
            if event == self.event && didChange {
                self.validateData()
                if keyPath == "startDate" && value != nil {
                    if let date = value as? NSDate {
                        let dayText = self.dayFormatter.stringFromDate(date)
                        self.dayLabel.text = dayText.uppercaseString
                    }
                }
            }
        }
    }
    
}

// MARK: - Shared UI

extension EventViewController: UIAlertViewDelegate {
    
    private func updateLayoutForView(view: UIView, withDuration duration: NSTimeInterval, usingSpring: Bool = true,
                 options: UIViewAnimationOptions, completion: ((Bool) -> Void)!)
    {
        view.setNeedsUpdateConstraints()
        UIView.animateWithDuration( duration, delay: 0.0,
            usingSpringWithDamping: (usingSpring ? 0.7 : 1.0), initialSpringVelocity: 0.0,
            options: options | .BeginFromCurrentState,
            animations: { view.layoutIfNeeded() },
            completion: { finished in
                if completion != nil {
                    completion(finished)
                }
            }
        )
    }
    
    private func shiftCurrentInputViewToView(view: UIView?) {
        // Guard.
        if view == self.currentInputView { return }
        // Re-focus previously focused input.
        if view == nil && self.previousInputView != nil && !self.isAttemptingDismissal {
            switch self.previousInputView! {
            case self.descriptionView:
                self.descriptionView.becomeFirstResponder()
            case self.datePicker:
                self.toggleDatePickerDrawerAppearance(true)
            default:
                break
            }
            // Update.
            self.currentInputView = self.previousInputView
        } else {
            var shouldPerformWaitingSegue = view == nil
            // Update.
            self.previousInputView = self.currentInputView
            // Blur currently focused input.
            if let previousInputView = self.previousInputView {
                switch previousInputView {
                case self.descriptionView:
                    self.descriptionView.resignFirstResponder() // TODO: Necessary?
                case self.datePicker:
                    self.toggleDatePickerDrawerAppearance(false)
                    shouldPerformWaitingSegue = false
                default:
                    break
                }
            }
            // Update.
            self.currentInputView = view
            // Retry any waiting segues.
            if shouldPerformWaitingSegue {
                self.performWaitingSegue()
            }
        }
    }
    
    private func performWaitingSegue() {
        if let identifier = self.waitingSegueIdentifier {
            self.isAttemptingDismissal = false
            let delay = Int64(0.3 * Double(NSEC_PER_SEC))
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue()) {
                self.performSegueWithIdentifier(identifier, sender: self)
                self.waitingSegueIdentifier = nil
            }
        }
    }
    
    private func resetSubviews() {
        self.dayLabel.text = nil
        self.descriptionView.text = nil
    }
    
    private func toggleErrorMessage(visible: Bool) {
        if visible {
            self.errorMessageView.show()
        } else {
            self.errorMessageView.dismissWithClickedButtonIndex(self.acknowledgeErrorButtonIndex!, animated: true)
        }
    }
    
    // MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if alertView == self.errorMessageView && buttonIndex == self.acknowledgeErrorButtonIndex {
            self.toggleErrorMessage(false)
        }
    }
    
}

// MARK: - Day Menu UI

extension EventViewController {
    
    private func setUpDayMenu() {
        // Define.
        self.todayIdentifier = NSLocalizedString("Today", comment: "")
        self.tomorrowIdentifier = NSLocalizedString("Tomorrow", comment: "")
        self.laterIdentifier = NSLocalizedString("Later", comment: "")
        self.dayMenuView.accessibilityLabel = NSLocalizedString(ETLabel.EventScreenTitle.toRaw(), comment: "")
        self.dayLabel.textColor = self.appearanceManager.lightGrayTextColor
        self.dayMenuView.textColor = self.appearanceManager.darkGrayTextColor
        // Add items.
        for identifier in [self.todayIdentifier, self.tomorrowIdentifier, self.laterIdentifier] {
            // Decide type.
            var type: ETNavigationItemType = .Label
            let isButton = contains([self.laterIdentifier] as [String], identifier)
            if isButton {
                type = .Button
            }
            // Common setup.
            let item = self.dayMenuView.addItemOfType(type, withText: identifier)
            item.accessibilityLabel = NSString.localizedStringWithFormat(
                NSLocalizedString(ETLabel.FormatDayOption.toRaw(), comment: ""),
                identifier
            )
            // Specific setup.
            if identifier == self.laterIdentifier {
                // Later item.
                if let button = item as? UIButton {
                    button.addTarget(self, action: "toggleDatePicking", forControlEvents: .TouchUpInside)
                    self.laterItem = button
                }
                self.datePicker.minimumDate = self.dateFromDayIdentifier(self.laterIdentifier)
            }
        }
        // Observe.
        self.dayMenuView.addObserver(self, forKeyPath: "visibleItem", options: .New | .Old, context: &observerContext)
        // Commit.
        self.dayMenuView.processItems()
    }
    
    private func tearDownDayMenu() {
        self.laterItem.removeTarget(self, action: "toggleDatePicking", forControlEvents: .TouchUpInside)
        self.dayMenuView.removeObserver(self, forKeyPath: "visibleItem", context: &observerContext)
    }
    
    private func toggleDatePickerDrawerAppearance(visible: Bool) {
        if self.isDatePickerVisible == visible { return }
        self.datePickerDrawerHeightConstraint.constant = visible ? self.datePicker.frame.size.height : 1.0
        self.dayLabel.hidden = true // TODO: Update layout?
        self.updateLayoutForView(self.view, withDuration: DatePickerAppearanceTransitionDuration, options: .CurveEaseInOut) { finished in
            self.isDatePickerVisible = visible
            if visible {
                self.shiftCurrentInputViewToView(self.datePicker)
            } else {
                if self.currentInputView === self.datePicker {
                    self.shiftCurrentInputViewToView(nil)
                }
                self.performWaitingSegue()
            }
        }
    }
    
}

// MARK: - Description UI

extension EventViewController: UIScrollViewDelegate, UITextViewDelegate {
    
    private func setUpDescriptionView() {
        self.descriptionContainerView.layer.mask = CAGradientLayer()
        self.toggleDescriptionTopMask(false)
        self.descriptionView.contentInset = UIEdgeInsets(top: -10.0, left: 0.0, bottom: 0.0, right: 0.0)
        self.descriptionView.scrollIndicatorInsets = UIEdgeInsets(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)
    }

    private func toggleDescriptionTopMask(visible: Bool) {
        let whiteColor = UIColor.whiteColor()
        let clearColor = UIColor.clearColor()
        let maskLayer = self.descriptionContainerView.layer.mask as CAGradientLayer
        let topColor = !visible ? whiteColor : clearColor
        if let colors = maskLayer.colors as? [CGColor] {
            if CGColorEqualToColor(topColor.CGColor, colors[0]) { return }
            maskLayer.colors = [topColor.CGColor, whiteColor.CGColor, whiteColor.CGColor, clearColor.CGColor] as [AnyObject]
        }
    }

    private func updateDescriptionTopMask() {
        let maskLayer = self.descriptionContainerView.layer.mask as CAGradientLayer
        let heightRatio = 20.0 / self.descriptionContainerView.frame.size.height
        maskLayer.locations = [0.0, heightRatio, 1.0 - heightRatio, 1.0]
        maskLayer.frame = self.descriptionContainerView.frame
    }
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView!) {
        let contentOffset = scrollView.contentOffset.y
        if scrollView != self.descriptionView || contentOffset > 44.0 { return }
        let shouldHideTopMask = self.descriptionView.text.isEmpty || contentOffset <= fabs(scrollView.scrollIndicatorInsets.top)
        self.toggleDescriptionTopMask(!shouldHideTopMask)
    }
    
    // MARK: UITextViewDelegate

    func textViewDidBeginEditing(textView: UITextView!) {
        self.shiftCurrentInputViewToView(textView)
        self.toggleDatePickerDrawerAppearance(false)
    }
    
    func textViewDidChange(textView: UITextView!) {
        self.event.title = textView.text
    }
    
    func textViewDidEndEditing(textView: UITextView!) {
        var value: AnyObject? = textView.text
        var error: NSError?
        if self.event.validateValue(&value, forKey: "title", error: &error) {
            self.event.title = value as? String
        }
        textView.text = value as? String
        if self.currentInputView == textView {
            self.shiftCurrentInputViewToView(nil)
        }
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
        self.timeItem.title = ETIcon.Clock.toRaw()
        self.locationItem.title = ETIcon.MapPin.toRaw()
        self.saveItem.title = ETIcon.CheckCircle.toRaw()
        // Set initial attributes.
        var attributes = BaseEditToolbarIconTitleAttributes
        attributes[NSForegroundColorAttributeName] = self.appearanceManager.lightGrayIconColor
        // For all actual buttons.
        for item in self.editToolbar.items as [UIBarButtonItem] {
            if item.width == 0.0 {
                // Apply initial attributes.
                let iconFont = attributes[NSFontAttributeName]! as UIFont
                item.setTitleTextAttributes(attributes, forState: .Normal)
                // Adjust icon layout.
                item.width = round(iconFont.pointSize + 1.15)
            }
        }
    }
    
    private func updateSaveBarButtonItem() {
        let saveItemColor = self.isDataValid ? self.appearanceManager.greenColor : self.appearanceManager.lightGrayIconColor
        var attributes = BaseEditToolbarIconTitleAttributes
        attributes[NSForegroundColorAttributeName] = saveItemColor
        self.saveItem.setTitleTextAttributes(attributes, forState: .Normal)
    }
    
}