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

class EventViewController: FormViewController {

    // MARK: State
    
    var event: EKEvent!
    
    private var isDatePickerDrawerExpanded = false
    private var dayIdentifier: String? {
        didSet {
            guard self.dayIdentifier != oldValue else { return }
            let shouldFocus = self.dayIdentifier == self.laterIdentifier
            let shouldBlur = !shouldFocus && self.activeDatePicker === self.dayDatePicker
            guard shouldFocus || shouldBlur else { return }
            self.focusState.shiftToInputView(shouldBlur ? nil : self.dayDatePicker)
        }
    }

    private var isEditingEvent: Bool {
        return self.event?.eventIdentifier != nil
    }
    
    // MARK: Subviews & Appearance
    
    @IBOutlet private var dayDatePicker: UIDatePicker!
    @IBOutlet private var timeDatePicker: UIDatePicker!
    private weak var activeDatePicker: UIDatePicker!

    @IBOutlet private var dayLabel: UILabel!
    @IBOutlet private var descriptionView: UITextView!
    @IBOutlet private var descriptionContainerView: UIView!

    @IBOutlet private var editToolbar: UIToolbar!
    @IBOutlet private var timeItem: IconBarButtonItem!
    @IBOutlet private var locationItem: IconBarButtonItem!
    @IBOutlet private var saveItem: IconBarButtonItem!

    @IBOutlet private var dayMenuView: NavigationTitlePickerView!
    
    var descriptionViewFrame: CGRect { return self.descriptionContainerView.frame ?? CGRectZero }
    
    private lazy var errorViewController: UIAlertController! = {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        alertController.addAction(
            UIAlertAction(title: t("OK"), style: .Default, handler: { (action) in self.toggleErrorPresentation(false) })
        )
        return alertController
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
    
    private let todayIdentifier: String = t("Today")
    private let tomorrowIdentifier: String = t("Tomorrow")
    private let laterIdentifier: String = t("Later")
    private var orderedIdentifiers: [String] {
        return [self.todayIdentifier, self.tomorrowIdentifier, self.laterIdentifier]
    }

    // MARK: Helpers
    
    private lazy var dayFormatter: NSDateFormatter! = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM d, y · EEEE"
        return formatter
    }()

    private lazy var dayWithTimeFormatter: NSDateFormatter! = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM d, y · EEEE · h:mm a"
        return formatter
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
    required init?(coder aDecoder: NSCoder) {
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

        self.isDebuggingInputState = true
        self.resetSubviews()
        
        self.setUpNewEventIfNeeded()
        self.updateMinimumTimeDateForDate(self.event.startDate)
        self.setUpFormDataObjectForKVO([.New, .Old])

        self.setUpDayMenu()
        self.setUpDescriptionView()
        self.setUpEditToolbar()

        self.activeDatePicker = self.dayDatePicker
        self.toggleDrawerDatePickerAppearance()
        
        self.updateDescriptionTopMask()
        
        if self.isEditingEvent {
            self.updateInputViewsWithFormDataObject()
        } else {
            self.initializeInputViewsWithFormDataObject()
            self.updateDayIdentifierToItem(self.dayMenuView.visibleItem)
            self.focusInputView(self.descriptionView, completionHandler: nil)
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
    
    override func focusInputView(view: UIView, completionHandler: ((FormError?) -> Void)?) {
        let isToPicker = view is UIDatePicker
        let isFromPicker = self.focusState.previousInputView is UIDatePicker
        let shouldToggleDrawer = isToPicker || isFromPicker && !(isToPicker && isFromPicker)

        if isToPicker {
            self.activeDatePicker = view as! UIDatePicker
            self.toggleDrawerDatePickerAppearance()
        }

        if shouldToggleDrawer {
            self.toggleDatePickerDrawerAppearance(isToPicker, customDuration: nil, customOptions: nil) { (finished) in
                let error: FormError? = !finished ? .BecomeFirstResponderError : nil
                completionHandler?(error)
            }
        } else {
            super.focusInputView(view, completionHandler: completionHandler)
        }
    }
    override func blurInputView(view: UIView, withNextView nextView: UIView?, completionHandler: ((FormError?) -> Void)?) {
        let isToPicker = nextView is UIDatePicker
        let isFromPicker = view is UIDatePicker
        let shouldToggleDrawer = isToPicker || isFromPicker && !(isToPicker && isFromPicker)

        if isToPicker {
            self.activeDatePicker = nextView as! UIDatePicker
        }
        if isFromPicker {
            self.datePickerDidChange(view as! UIDatePicker)
        }

        if shouldToggleDrawer {
            self.toggleDatePickerDrawerAppearance(isToPicker, customDuration: nil, customOptions: nil) { (finished) in
                let error: FormError? = !finished ? .ResignFirstResponderError : nil
                completionHandler?(error)
            }
        } else {
            super.blurInputView(view, withNextView: nextView, completionHandler: completionHandler)
        }
    }

    override func shouldDismissalSegueWaitForInputView(view: UIView) -> Bool {
        let shouldByDefault = super.shouldDismissalSegueWaitForInputView(view)
        return !(view is UIDatePicker) || shouldByDefault
    }
    override func isDismissalSegue(identifier: String) -> Bool {
        let isByDefault = super.isDismissalSegue(identifier)
        return isByDefault || identifier == self.dismissAfterSaveSegueIdentifier
    }

    // MARK: Data Handling

    override var dismissAfterSaveSegueIdentifier: String? {
        var presentingViewController = self.presentingViewController
        if let navigationController = presentingViewController as? NavigationController,
               topViewController = navigationController.topViewController
        {
            presentingViewController = topViewController
        }
        var segue = Segue.UnwindToDay
        if presentingViewController is MonthsViewController {
            segue = Segue.UnwindToMonths
        }
        return segue.rawValue
    }

    override func saveFormData() throws {
        try self.eventManager.saveEvent(self.event)
    }
    override func validateFormData() throws {
        try self.eventManager.validateEvent(self.event)
    }

    override func didChangeFormDataValue(value: AnyObject?, atKeyPath keyPath: String) {
        if case keyPath = "startDate",
           let startDate = value as? NSDate
        {
            self.timeItem.toggleState(.Filled, on: startDate.hasCustomTime)
            if startDate != self.timeDatePicker.date {
                self.setValue(startDate, forInputView: self.timeDatePicker)
                // Limit time picker if needed.
                self.updateMinimumTimeDateForDate(startDate)
            }
        }
    }

    override func didReceiveErrorOnFormSave(error: NSError) {
        if let userInfo = error.userInfo as? [String: String] {
            let description = userInfo[NSLocalizedDescriptionKey] ?? t("Unknown Error")
            let failureReason = userInfo[NSLocalizedFailureReasonErrorKey] ?? ""
            let recoverySuggestion = userInfo[NSLocalizedRecoverySuggestionErrorKey] ?? ""
            self.errorViewController.title = description.capitalizedString
                .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                .stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet())
            self.errorViewController.message = "\(failureReason) \(recoverySuggestion)"
                .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        }
    }
    override func didSaveFormData() {}
    override func didValidateFormData() {
        self.saveItem.toggleState(.Successful, on: self.isValid)
    }

    override func toggleErrorPresentation(visible: Bool) {
        if visible {
            self.presentViewController(self.errorViewController, animated: true, completion: nil)
        } else {
            self.errorViewController.dismissViewControllerAnimated(true, completion: nil)
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
    
    override func infoForInputView(view: UIView) -> (name: String, valueKeyPath: String, emptyValue: AnyObject) {
        let name: String!
        let valueKeyPath: String!
        let emptyValue: AnyObject!
        switch view {
        case self.descriptionView:
            name = "Event Description"
            valueKeyPath = "title"
            emptyValue = ""
        case self.dayDatePicker, self.timeDatePicker:
            switch view {
            case self.dayDatePicker:  name = "Day Picker"
            case self.timeDatePicker: name = "Time Picker"
            default: fatalError("Unknown picker.")
            }
            valueKeyPath = "startDate"
            emptyValue = NSDate().dayDate
        default: fatalError("Unimplemented form data key.")
        }
        return (name, valueKeyPath, emptyValue)
    }

    override func didCommitValueForInputView(view: UIView) {
        switch view {
        case self.dayDatePicker, self.timeDatePicker:
            let date = (view as! UIDatePicker).date
            let dayText = self.dateFormatterForDate(date).stringFromDate(date)
            self.dayLabel.text = dayText.uppercaseString
        default: break
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func toggleDayPicking(sender: UIView) {
        let shouldBlur = self.focusState.currentInputView == self.dayDatePicker
        self.focusState.shiftToInputView(shouldBlur ? nil : self.dayDatePicker)
    }

    @IBAction private func toggleTimePicking(sender: UIView) {
        let shouldBlur = self.focusState.currentInputView == self.timeDatePicker
        self.focusState.shiftToInputView(shouldBlur ? nil : self.timeDatePicker)
    }

    @IBAction private func dismissToPresentingViewController(sender: AnyObject) {
        guard let identifier = self.dismissAfterSaveSegueIdentifier else { return }
        self.performSegueWithIdentifier(identifier, sender: self)
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
                self.toggleDatePickerDrawerAppearance(false, customDuration: duration, customOptions: options)
            }
            self.toolbarBottomEdgeConstraint.constant = constant + self.initialToolbarBottomEdgeConstant
            self.updateLayoutForView(self.editToolbar, withDuration: duration, usingSpring: false, options: options, completion: nil)
        }
    }
    
}

// MARK: - Data

extension EventViewController {
    
    private func setUpNewEventIfNeeded() {
        guard !self.isEditingEvent else { return }
        self.event = EKEvent(eventStore: self.eventManager.store)
        self.event.startDate = NSDate().dayDate!
    }
    
    private func dateFromDayIdentifier(identifier: String, withTime: Bool = true) -> NSDate {
        let numberOfDays: Int!
        switch identifier {
        case self.tomorrowIdentifier: numberOfDays = 1
        case self.laterIdentifier: numberOfDays = 2
        default: numberOfDays = 0
        }
        var date = NSDate().dayDateFromAddingDays(numberOfDays)
        // Account for time.
        if withTime {
            date = date.dateWithTime(self.timeDatePicker.date)
        }
        // Return existing date if fitting when editing.
        let existingDate = self.event.startDate
        if self.isEditingEvent && identifier == self.laterIdentifier &&
           existingDate.laterDate(date) == existingDate
        {
            return existingDate
        }
        return date
    }
    
    private func itemFromDate(date: NSDate) -> UIView {
        let normalizedDate = date.dayDate
        let todayDate = NSDate().dayDate
        let tomorrowDate = NSDate().dayDateFromAddingDays(1)
        let index: Int!
        if normalizedDate == todayDate {
            index = self.orderedIdentifiers.indexOf { $0 == self.todayIdentifier }!
        } else if normalizedDate == tomorrowDate {
            index = self.orderedIdentifiers.indexOf { $0 == self.tomorrowIdentifier }!
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
        // NOTE: This manual update is an exception to FormViewController conventions.
        let dayDate = self.dateFromDayIdentifier(self.dayIdentifier!)
        self.event.startDate = dayDate
    }

    private func dateFormatterForDate(date: NSDate) -> NSDateFormatter {
        return date.hasCustomTime ? self.dayWithTimeFormatter : self.dayFormatter
    }

    private func updateMinimumTimeDateForDate(date: NSDate) {
        let calendar = NSCalendar.currentCalendar()
        if calendar.isDateInToday(date) {
            let date = NSDate()
            self.timeDatePicker.minimumDate = date.hourDateFromAddingHours(
                calendar.component(.Hour, fromDate: date) == 23 ? 0 : 1
            )
        } else {
            self.timeDatePicker.minimumDate = nil
            self.timeDatePicker.date = date.dayDate!
        }
    }

    // MARK: KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?,
                  change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        guard context == &sharedObserverContext else { return }
        let (_, newValue, didChange) = change_result(change)
        guard didChange else { return }
        if object is EKEvent && keyPath == "startDate",
           let date = newValue as? NSDate
        {
            let dayText = self.dateFormatterForDate(date).stringFromDate(date)
            self.dayLabel.text = dayText.uppercaseString
        }
    }
    
}

// MARK: - Shared UI

extension EventViewController {
    
    private func updateLayoutForView(view: UIView, withDuration duration: NSTimeInterval, usingSpring: Bool = true,
                 options: UIViewAnimationOptions, completion: ((Bool) -> Void)!)
    {
        var animationOptions = options
        animationOptions.insert(.BeginFromCurrentState)
        let animations = { view.layoutIfNeeded() }
        let animationCompletion: (Bool) -> Void = { finished in
            if let completion = completion {
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
        self.dayMenuView.accessibilityLabel = t(Label.EventScreenTitle.rawValue)
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
        guard visible != self.isDatePickerDrawerExpanded else {
            completion?(true)
            return visible
        }
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
                    //self.performDismissalSegueWithWaitDurationIfNeeded()
                }
                completion?(finished)
            }
        }
        if visible {
            if self.focusState.currentInputView === self.descriptionView { delay = 0.3 }
            dispatch_after(delay, block: toggle)
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
        if self.isDebuggingInputState {
            print("Toggled active to \(active) for \(datePicker.accessibilityLabel)")
        }
    }

    private func toggleDrawerDatePickerAppearance() {
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

    // MARK: NavigationTitleScrollViewDataSource
    
    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int {
        return self.orderedIdentifiers.count
    }
    
    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView? {
        // For each item, decide type, then add and configure.
        let identifier = self.orderedIdentifiers[index]
        let buttonIdentifiers = [self.laterIdentifier]
        let type: NavigationTitleItemType = buttonIdentifiers.contains(identifier) ? .Button : .Label
        if let item = self.dayMenuView.newItemOfType(type, withText: identifier) {
            item.accessibilityLabel = NSString.localizedStringWithFormat(t(Label.FormatDayOption.rawValue), identifier) as String
            if identifier == self.laterIdentifier,
               let button = item as? UIButton
            {
                button.addTarget(self, action: "toggleDayPicking:", forControlEvents: .TouchUpInside)
                self.dayDatePicker.minimumDate = self.dateFromDayIdentifier(identifier, withTime: false)
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

extension EventViewController {
    
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
        guard scrollView == self.descriptionView && contentOffset <= 44.0 else { return }
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
        self.timeItem.iconTitle = Icon.Clock.rawValue
        self.locationItem.iconTitle = Icon.MapPin.rawValue
        self.saveItem.iconTitle = Icon.CheckCircle.rawValue
        if self.isEditingEvent {
            self.timeItem.toggleState(.Filled, on: self.event.startDate.hasCustomTime)
        }
    }

}