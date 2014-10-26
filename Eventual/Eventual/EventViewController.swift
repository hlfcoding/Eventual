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

@objc(ETEventViewController) class EventViewController: FormViewController {

    // MARK: State
    
    var event: EKEvent!
    
    private var isDatePickerVisible = false
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
        self.acknowledgeErrorButtonIndex = alertView.addButtonWithTitle(t("OK"))
        return alertView
    }()

    // TODO: Class properties not yet supported, sigh.
    private let DatePickerAppearanceTransitionDuration: NSTimeInterval = 0.3
    private let BaseEditToolbarIconTitleAttributes: [String: AnyObject] = [
        NSFontAttributeName: UIFont(name: "eventual", size: AppearanceManager.defaultManager().iconBarButtonItemFontSize)
    ]

    // MARK: Constraints
    
    @IBOutlet private var datePickerDrawerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var toolbarBottomEdgeConstraint: NSLayoutConstraint!
    private var initialToolbarBottomEdgeConstant: CGFloat!

    // MARK: Defines
    
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
    
    // MARK: - FormViewController
    
    // MARK: Input State
    
    override func focusInputView(view: UIView) -> Bool {
        switch view {
        case self.datePicker:
            self.toggleDatePickerDrawerAppearance(true)
            return true
        default:
            return super.focusInputView(view)
        }
    }
    override func blurInputView(view: UIView) -> Bool {
        switch view {
        case self.datePicker:
            self.toggleDatePickerDrawerAppearance(false)
            return true
        default:
            return super.blurInputView(view)
        }
    }
    
    override func shouldDismissalSegueWaitForInputView(view: UIView) -> Bool {
        let shouldByDefault = super.shouldDismissalSegueWaitForInputView(view)
        return view != self.datePicker || shouldByDefault
    }
    override func isDismissalSegue(identifier: String) -> Bool {
        let isByDefault = super.isDismissalSegue(identifier)
        return identifier == ETSegue.DismissToMonths.toRaw() || isByDefault
    }

    // MARK: Data Handling

    override var dismissAfterSaveSegueIdentifier: String? {
        return ETSegue.DismissToMonths.toRaw()
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
    
    override func didReceiveErrorOnFormSave(error: NSError) {
        if let userInfo = error.userInfo as? [String: String] {
            self.errorMessageView.title = userInfo[NSLocalizedDescriptionKey]!.capitalizedString
                .stringByReplacingOccurrencesOfString(". ", withString: "")
            self.errorMessageView.message =
            "\(userInfo[NSLocalizedFailureReasonErrorKey]!) \(userInfo[NSLocalizedRecoverySuggestionErrorKey]!)"
        }
    }
    override func didSaveFormData() {}
    override func didValidateFormData() {
        self.updateSaveBarButtonItem()
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
    
    override var formDataObjectKeys: [String] {
        return ["title", "startDate"]
    }
    
    override func infoForInputView(view: UIView) -> (key: String, emptyValue: AnyObject) {
        var key: String!
        var emptyValue: AnyObject!
        switch view {
        case self.descriptionView:
            key = "title"
            emptyValue = ""
        case self.datePicker:
            key = "startDate"
            emptyValue = NSDate.date()
        default: fatalError("Unimplemented form data key.")
        }
        return (key, emptyValue)
    }
    
    override func didCommitValueForInputView(view: UIView) {
        switch view {
        case self.datePicker:
            let dayText = self.dayFormatter.stringFromDate(self.datePicker.date)
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
        self.datePickerDidChange(self.datePicker)
    }
    
    @IBAction func completeDatePicking(sender: AnyObject) {
        self.datePickerDidEndEditing(self.datePicker)
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
    
    // MARK: - Handlers
    
    func updateOnKeyboardAppearanceWithNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject] {
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]! as NSTimeInterval
            let options = UIViewAnimationOptions.fromRaw(userInfo[UIKeyboardAnimationCurveUserInfoKey]! as UInt)
            var constant = 0.0 as CGFloat
            if notification.name == UIKeyboardWillShowNotification {
                let frame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as NSValue).CGRectValue()
                constant = (frame.size.height > frame.size.width) ? frame.size.width : frame.size.height
                self.toggleDatePickerDrawerAppearance(false, customDuration: duration, customOptions: options)
            }
            self.toolbarBottomEdgeConstraint.constant = constant + self.initialToolbarBottomEdgeConstant
            // TODO: Flawless animation sync using inputAccessoryView, but would require
            // also transplanting and sticking it to bottom edge.
            self.editToolbar.setNeedsUpdateConstraints()
            self.updateLayoutForView(self.editToolbar, withDuration: duration, usingSpring: false, options: options!, completion: nil)
        }
    }
    
}

// MARK: - Data

extension EventViewController {
    
    private func setUpNewEvent() {
        if self.event != nil { return }
        self.event = EKEvent(eventStore: self.eventManager.store)
        self.setUpFormDataObjectForKVO(options:.New | .Old)
    }
    
    private func dateFromDayIdentifier(identifier: String) -> NSDate {
        var numberOfDays: Int = 0;
        switch identifier {
        case self.tomorrowIdentifier: numberOfDays = 1
        case self.laterIdentifier: numberOfDays = 2
        default: break
        }
        let date = NSDate.dateAsBeginningOfDayFromAddingDays(numberOfDays, toDate: NSDate.date())
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
                  change: [NSObject: AnyObject]!, context: UnsafeMutablePointer<()>)
    {
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        if context != &sharedObserverContext { return }
        let (oldValue: AnyObject?, newValue: AnyObject?, didChange) = change_result(change)
        if !didChange { return }
        if let view = object as? NavigationTitleScrollView {
            if view === self.dayMenuView && keyPath == "visibleItem" {
                self.updateDayIdentifierToItem(newValue! as? UIView)
            }
        } else if object is EKEvent && keyPath == "startDate" {
            if let date = newValue as? NSDate {
                let dayText = self.dayFormatter.stringFromDate(date)
                self.dayLabel.text = dayText.uppercaseString
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
    
    private func resetSubviews() {
        self.dayLabel.text = nil
        self.descriptionView.text = nil
    }
    
    // MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if alertView === self.errorMessageView && buttonIndex == self.acknowledgeErrorButtonIndex {
            self.toggleErrorPresentation(false)
        }
    }
    
}

// MARK: - Day Menu UI

extension EventViewController {
    
    private func setUpDayMenu() {
        // Define.
        self.todayIdentifier = t("Today")
        self.tomorrowIdentifier = t("Tomorrow")
        self.laterIdentifier = t("Later")
        self.dayMenuView.accessibilityLabel = t(ETLabel.EventScreenTitle.toRaw())
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
                t(ETLabel.FormatDayOption.toRaw()),
                identifier
            )
            // Specific setup.
            if identifier == self.laterIdentifier {
                // Later item.
                if let button = item as? UIButton {
                    button.addTarget(self, action: "toggleDatePicking:", forControlEvents: .TouchUpInside)
                    // NOTE: Temporarily disabled.
                    button.userInteractionEnabled = false
                    self.laterItem = button
                }
                self.datePicker.minimumDate = self.dateFromDayIdentifier(self.laterIdentifier)
            }
        }
        // Observe.
        self.dayMenuView.addObserver(self, forKeyPath: "visibleItem", options: .New | .Old, context: &sharedObserverContext)
        // Commit.
        self.dayMenuView.processItems()
    }
    
    private func tearDownDayMenu() {
        self.laterItem.removeTarget(self, action: "toggleDatePicking:", forControlEvents: .TouchUpInside)
        self.dayMenuView.removeObserver(self, forKeyPath: "visibleItem", context: &sharedObserverContext)
    }
    
    private func toggleDatePickerDrawerAppearance(visible: Bool,
                                                  customDuration: NSTimeInterval? = nil,
                                                  customOptions: UIViewAnimationOptions? = nil)
    {
        if self.isDatePickerVisible == visible { return }
        let duration = customDuration ?? DatePickerAppearanceTransitionDuration
        let options = customOptions ?? .CurveEaseInOut
        var delay: NSTimeInterval = 0.0
        func toggle() {
            self.datePickerDrawerHeightConstraint.constant = visible ? self.datePicker.frame.size.height : 1.0
            self.dayLabel.hidden = visible // TODO: Update layout?
            self.updateLayoutForView(self.view, withDuration: duration, options: options) { finished in
                self.isDatePickerVisible = visible
                if !visible {
                    if self.currentInputView === self.datePicker {
                        self.shiftCurrentInputViewToView(nil)
                    }
                    self.performDismissalSegueWithWaitDuration()
                }
            }
        }
        if visible {
            if self.currentInputView === self.descriptionView { delay = 0.3 }
            self.shiftCurrentInputViewToView(self.datePicker)
            dispatch_after(delay, toggle)
        } else {
            toggle()
        }
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
        let maskLayer = self.descriptionContainerView.layer.mask as CAGradientLayer
        let topColor = !visible ? whiteColor : clearColor
        // if CGColorEqualToColor(topColor, maskLayer.colors.first as CGColor) { return } // TODO: Unwrap safely before checking.
        maskLayer.colors = [topColor, whiteColor, whiteColor, clearColor] as [AnyObject]
    }

    private func updateDescriptionTopMask() {
        let maskLayer = self.descriptionContainerView.layer.mask as CAGradientLayer
        let heightRatio = 20.0 / self.descriptionContainerView.frame.size.height
        maskLayer.locations = [0.0, heightRatio, 1.0 - heightRatio, 1.0]
        maskLayer.frame = self.descriptionContainerView.bounds
    }
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView!) {
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
        let saveItemColor = self.validationResult.isValid ? self.appearanceManager.greenColor : self.appearanceManager.lightGrayIconColor
        var attributes = BaseEditToolbarIconTitleAttributes
        attributes[NSForegroundColorAttributeName] = saveItemColor
        self.saveItem.setTitleTextAttributes(attributes, forState: .Normal)
    }
    
}