//
//  EventViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import QuartzCore
import EventKit

/**
 Alias public, non `UIViewController` API for testability.
 */
protocol EventViewControllerState: NSObjectProtocol {

    var event: Event! { get }

}

final class EventViewController: FormViewController, EventViewControllerState, CoordinatedViewController {

    var unwindSegueIdentifier: Segue?

    // MARK: State

    weak var delegate: CoordinatedViewControllerDelegate!

    var event: Event!

    private var didSaveEvent = false

    // MARK: Subviews & Appearance

    @IBOutlet private(set) var dayDatePicker: UIDatePicker!
    @IBOutlet private(set) var timeDatePicker: UIDatePicker!
    // NOTE: This doesn't correlate with picker visibility.
    private weak var activeDatePicker: UIDatePicker!

    @IBOutlet private(set) var dayLabel: UILabel!
    @IBOutlet private(set) var descriptionView: MaskedTextView!

    @IBOutlet private(set) var detailsView: EventDetailsView!

    @IBOutlet private(set) var editToolbar: UIToolbar!
    @IBOutlet private(set) var timeItem: IconBarButtonItem!
    @IBOutlet private(set) var locationItem: IconBarButtonItem!
    @IBOutlet private(set) var saveItem: IconBarButtonItem!

    @IBOutlet private(set) var dayMenuView: NavigationTitlePickerView!
    private var dayMenu: DayMenuDataSource!

    private lazy var errorViewController: UIAlertController! = {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        alertController.addAction(
            UIAlertAction(title: t("OK", "button"), style: .Default)
            { [unowned self] action in self.toggleErrorPresentation(false) }
        )
        return alertController
    }()

    private let datePickerAppearanceDuration: NSTimeInterval = 0.3
    private var keyboardAnimationDuration: NSTimeInterval?

    // MARK: Constraints & Related State

    @IBOutlet private var datePickerDrawerHeightConstraint: NSLayoutConstraint!
    private var isDatePickerDrawerExpanded = false

    @IBOutlet private var dayLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var dayLabelTopEdgeConstraint: NSLayoutConstraint!
    private var initialDayLabelHeightConstant: CGFloat!
    private var initialDayLabelTopEdgeConstant: CGFloat!

    @IBOutlet private var toolbarBottomEdgeConstraint: NSLayoutConstraint!
    private var initialToolbarBottomEdgeConstant: CGFloat!

    // MARK: Helpers

    private var eventManager: EventManager { return EventManager.defaultManager }

    // MARK: - Initializers

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUp()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    deinit {
        tearDown()
    }

    private func setUp() {
        customizeNavigationItem()

        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(
            self, selector: #selector(updateOnKeyboardAppearanceWithNotification(_:)),
            name: UIKeyboardWillShowNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(updateOnKeyboardAppearanceWithNotification(_:)),
            name: UIKeyboardWillHideNotification, object: nil
        )
    }
    private func tearDown() {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
        tearDownDayMenu()
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAccessibility(nil)

        guard unwindSegueIdentifier != nil else { preconditionFailure("Requires unwind segue identifier.") }
        guard navigationController != nil else { preconditionFailure("Requires being a navigation bar.") }

        //isDebuggingInputState = true

        resetSubviews()

        // Setup data.
        setUpNewEventIfNeeded()

        // Setup subviews.
        setUpDayMenu()
        detailsView.event = event
        setUpEditToolbar()

        // Setup state.
        activeDatePicker = dayDatePicker
        if event.isNew {
            dataSource.initializeInputViewsWithFormDataObject()
        } else {
            event.allDay = false // So time-picking works.
            dataSource.initializeInputViewsWithFormDataObject()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        toggleDayMenuCloak(true)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        descriptionView.setUpTopMask()
        toggleDayMenuCloak(false)
        toggleDrawerDatePickerAppearance()
        updateDatePickerMinimumsForDate(event.startDate, withReset: false)

        if locationItem.state == .Active {
            locationItem.toggleState(.Active, on: false)
        }
        if event.hasLocation {
            locationItem.toggleState(.Filled, on: true)
            renderAccessibilityValueForElement(locationItem, value: true)
        }
        if event.isNew {
            focusInputView(descriptionView, completionHandler: nil)
        }
    }

    override func performSegueWithIdentifier(identifier: String, sender: AnyObject?) {
        if isDismissalSegue(identifier) {
            clearEventEditsIfNeeded()
        }
        super.performSegueWithIdentifier(identifier, sender: sender)
    }

    // MARK: - FormViewController

    // MARK: FormFocusStateDelegate

    override func focusInputView(view: UIView, completionHandler: ((FormError?) -> Void)?) {
        let isToPicker = view is UIDatePicker
        let isFromPicker = focusState.previousInputView is UIDatePicker
        let shouldToggleDrawer = isToPicker || isFromPicker && !(isToPicker && isFromPicker)

        if isToPicker {
            activeDatePicker = view as! UIDatePicker
            if activeDatePicker.hidden {
                toggleDrawerDatePickerAppearance()
            }
            if view == timeDatePicker {
                timeItem.toggleState(.Active, on: true)
            }
        }

        if shouldToggleDrawer {
            // NOTE: Redundancy ok.
            var customDelay: NSTimeInterval = 0
            let shouldDelay = isToPicker && focusState.previousInputView === descriptionView
            if shouldDelay, let duration = keyboardAnimationDuration {
                customDelay = duration
            }
            toggleDatePickerDrawerAppearance(isToPicker, customDelay: customDelay) { (finished) in
                let error: FormError? = !finished ? .BecomeFirstResponderError : nil
                completionHandler?(error)
            }
            super.focusInputView(view, completionHandler: nil)
        } else {
            super.focusInputView(view, completionHandler: completionHandler)
        }
    }
    override func blurInputView(view: UIView, withNextView nextView: UIView?, completionHandler: ((FormError?) -> Void)?) {
        let isToPicker = nextView is UIDatePicker
        let isFromPicker = view is UIDatePicker
        let shouldToggleDrawer = isToPicker || isFromPicker && !(isToPicker && isFromPicker)

        if isToPicker {
            activeDatePicker = nextView as! UIDatePicker
            if activeDatePicker.hidden {
                toggleDrawerDatePickerAppearance()
            }
        }
        if isFromPicker {
            if view == timeDatePicker {
                timeItem.toggleState(.Active, on: false)
            }
        }

        if shouldToggleDrawer {
            // NOTE: Redundancy ok.
            var customDelay: NSTimeInterval = 0
            let shouldDelay = isToPicker && view === descriptionView
            if shouldDelay, let duration = keyboardAnimationDuration {
                customDelay = duration
            }
            toggleDatePickerDrawerAppearance(isToPicker, customDelay: customDelay) { (finished) in
                let error: FormError? = !finished ? .ResignFirstResponderError : nil
                completionHandler?(error)
            }
            super.blurInputView(view, withNextView: nextView, completionHandler: nil)
        } else {
            super.blurInputView(view, withNextView: nextView, completionHandler: completionHandler)
        }
    }

    override func shouldRefocusInputView(view: UIView, fromView currentView: UIView?) -> Bool {
        var should = super.shouldRefocusInputView(view, fromView: currentView)

        if view == dayDatePicker && dayMenu.selectedItem != .Later {
            should = false
        }

        return should
    }

    override func isDismissalSegue(identifier: String) -> Bool {
        return identifier == dismissAfterSaveSegueIdentifier
    }

    override var dismissAfterSaveSegueIdentifier: String? {
        return unwindSegueIdentifier?.rawValue
    }

    // MARK: FormDataSourceDelegate

    override var formDataObject: NSObject { return event }

    override var formDataValueToInputView: KeyPathsMap {
        return [
            "title": "descriptionView",
            "startDate": ["dayDatePicker", "timeDatePicker"]
        ]
    }

    override func infoForInputView(view: UIView) -> (name: String, valueKeyPath: String, emptyValue: AnyObject) {
        let name: String!, valueKeyPath: String!, emptyValue: AnyObject!
        switch view {
        case descriptionView:
            name = "Event Description"
            valueKeyPath = "title"
            emptyValue = ""
        case dayDatePicker, timeDatePicker:
            switch view {
            case dayDatePicker:  name = "Day Picker"
            case timeDatePicker: name = "Time Picker"
            default: fatalError("Unknown picker.")
            }
            valueKeyPath = "startDate"
            emptyValue = NSDate().dayDate
        default: fatalError("Unknown field.")
        }
        return (name, valueKeyPath, emptyValue)
    }

    override func formDidChangeDataObjectValue(value: AnyObject?, atKeyPath keyPath: String) {
        if case keyPath = "startDate", let startDate = value as? NSDate {
            let filled = startDate.hasCustomTime
            if filled && timeItem.state == .Active {
                // Suspend if needed.
                timeItem.toggleState(.Active, on: false)
            }
            toggleTimeItemFilled(filled)
            if !filled && isDatePickerVisible(timeDatePicker)  {
                // Restore if needed.
                timeItem.toggleState(.Active, on: true)
            }

            if startDate != timeDatePicker.date {
                dataSource.setValue(startDate, forInputView: timeDatePicker)
                // Limit time picker if needed.
                updateDatePickerMinimumsForDate(startDate)
            }
            updateDayLabel(date: startDate)

            detailsView.updateTimeAndLocationLabelAnimated()

        } else if case keyPath = "location" {
            detailsView.updateTimeAndLocationLabelAnimated()
        }

        super.formDidChangeDataObjectValue(value, atKeyPath: keyPath)
    }

    override func formDidCommitValueForInputView(view: UIView) {
        switch view {
        case dayDatePicker: updateDayLabel(date: dayDatePicker.date)
        default: break
        }
    }

    // MARK: Submission

    override func saveFormData() throws {
        try eventManager.saveEvent(event)
        didSaveEvent = true
    }

    override func didReceiveErrorOnFormSave(error: NSError) {
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

    // MARK: - UITextView Placeholder Text

    override func placeholderForTextView(textView: UITextView) -> String? {
        switch textView {
        case descriptionView: return t("Event", "input placeholder")
        default: return nil
        }
    }

    // MARK: Validation

    override func validateFormData() throws {
        try eventManager.validateEvent(event)
    }

    override func didValidateFormData() {
        let on = isValid
        saveItem.toggleState(.Successful, on: on)
        renderAccessibilityValueForElement(saveItem, value: on)
    }

    override func toggleErrorPresentation(visible: Bool) {
        if visible {
            presentViewController(errorViewController, animated: true, completion: nil)
        } else {
            errorViewController.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    // MARK: - Actions

    @IBAction private func toggleDayPicking(sender: UIView) {
        let shouldBlur = focusState.currentInputView == dayDatePicker
        focusState.shiftToInputView(shouldBlur ? nil : dayDatePicker)
    }

    @IBAction private func toggleTimePicking(sender: UIBarButtonItem) {
        let shouldBlur = focusState.currentInputView == timeDatePicker
        focusState.shiftToInputView(shouldBlur ? nil : timeDatePicker)
    }

    @IBAction private func dismissToPresentingViewController(sender: AnyObject) {
        // Use the dismiss-after-save segue, but we're not saving.
        guard
            let identifier = unwindSegueIdentifier?.rawValue
            where shouldPerformSegueWithIdentifier(identifier, sender: self)
            else { return }
        performSegueWithIdentifier(identifier, sender: self)
    }

    @IBAction private func editDayDateFromDayLabel(tapRecognizer: UITapGestureRecognizer) {
        // TODO: Add itemFromIdentifier.
        guard let laterItemIndex = dayMenu.positionedItems.indexOf(.Later)
            else { return }

        let laterItem = dayMenuView.items[laterItemIndex]
        let needsManualUpdate = dayMenuView.visibleItem == laterItem

        dayMenuView.visibleItem = dayMenuView.items[laterItemIndex]

        if needsManualUpdate {
            navigationTitleScrollView(dayMenuView.scrollView, didChangeVisibleItem: laterItem)
        }
    }

    @IBAction private func handleLocationItemTap(sender: UIBarButtonItem) {
        locationItem.toggleState(.Active, on: true)
        guard let delegate = delegate as? EventViewControllerDelegate else { return }
        delegate.handleLocationButtonTapFromEventViewController(self);
    }

    // MARK: - Handlers

    func updateOnKeyboardAppearanceWithNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? UserInfo else { return }

        let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
        keyboardAnimationDuration = duration
        let options = UIViewAnimationOptions(rawValue: userInfo[UIKeyboardAnimationCurveUserInfoKey]! as! UInt)
        var keyboardHeight = 0 as CGFloat

        if notification.name == UIKeyboardWillShowNotification {
            let frame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
            keyboardHeight = min(frame.width, frame.height) // Keyboard's height is the smaller dimension.
            toggleDatePickerDrawerAppearance(false, customDuration: duration, customOptions: options)
        }

        toolbarBottomEdgeConstraint.constant = keyboardHeight + initialToolbarBottomEdgeConstant
        view.animateLayoutChangesWithDuration(duration, usingSpring: false, options: options, completion: nil)
    }

}

// MARK: - Data

extension EventViewController {

    private func setUpNewEventIfNeeded() {
        guard event == nil else { return }
        event = Event(entity: EKEvent(eventStore: eventManager.store))
        event.start()
    }

    private func clearEventEditsIfNeeded() {
        guard !event.isNew && !didSaveEvent else { return }
        event.resetChanges()
    }

    // MARK: Start Date

    private func changeDayMenuItem(item: DayMenuItem) {
        if
            let currentItem = dayMenu.selectedItem where currentItem != item && currentItem == .Later,
            let minimumDate = dayDatePicker.minimumDate {
            dayDatePicker.setDate(minimumDate, animated: false)
        }

        dayMenu.selectedItem = item
        renderAccessibilityValueForElement(dayMenuView, value: nil)

        // Invalidate end date, then update start date.
        // NOTE: This manual update is an exception to FormViewController conventions.
        let dayDate = dateFromDayMenuItem(dayMenu.selectedItem!, withTime: false, asLatest: true)
        dataSource.changeFormDataValue(dayDate, atKeyPath: "startDate")

        let shouldFocus = dayMenu.selectedItem == .Later
        let shouldBlur = !shouldFocus && focusState.currentInputView == dayDatePicker
        guard shouldFocus || shouldBlur else { return }

        focusState.shiftToInputView(shouldBlur ? nil : dayDatePicker)
    }

    private func dateFromDayMenuItem(item: DayMenuItem, withTime: Bool = true,
                                     asLatest: Bool = true) -> NSDate {
        var date = item.absoluteDate
        // Account for time.
        if withTime {
            date = date.dateWithTime(timeDatePicker.date)
        }
        // Return existing date if fitting when editing.
        let existingDate = event.startDate
        if asLatest && item == .Later && existingDate.laterDate(date) == existingDate {
            return existingDate
        }
        return date
    }

    private func itemFromDate(date: NSDate) -> UIView {
        let index = dayMenu.indexFromDate(date)
        return dayMenuView.items[index]
    }

    private func updateDatePickerMinimumsForDate(date: NSDate, withReset: Bool = true) {
        let calendar = NSCalendar.currentCalendar()
        if calendar.isDateInToday(date) {
            let minimumDate = NSDate().hourDateFromAddingHours(
                calendar.component(.Hour, fromDate: NSDate()) == 23 ? 0 : 1
            )
            if withReset && date.laterDate(minimumDate) == minimumDate {
                timeDatePicker.setDate(minimumDate, animated: false)
            }
            timeDatePicker.minimumDate = minimumDate
        } else {
            timeDatePicker.minimumDate = nil
            if withReset {
                timeDatePicker.setDate(date.dayDate, animated: false)
            }
        }

        dayDatePicker.minimumDate = dateFromDayMenuItem(.Later, asLatest: false)
    }

}

// MARK: - Shared UI

extension EventViewController {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard scrollView == descriptionView else { return }
        descriptionView.toggleTopMask(!descriptionView.shouldHideTopMask)
    }

    private func resetSubviews() {
        updateDayLabel(date: nil)
        descriptionView.text = nil
    }

}

// MARK: - Day Menu & Date Picker UI

extension EventViewController : NavigationTitleScrollViewDelegate {

    private func isDatePickerVisible(datePicker: UIDatePicker) -> Bool {
        return datePicker == activeDatePicker && datePicker == focusState.currentInputView
    }

    private func setUpDayMenu() {
        dayMenu = DayMenuDataSource()
        dayMenuView.delegate = self
        // Save initial state.
        initialDayLabelHeightConstant = dayLabelHeightConstraint.constant
        initialDayLabelTopEdgeConstant = dayLabelTopEdgeConstraint.constant
        // Style day label and menu.
        dayLabel.textColor = Appearance.lightGrayTextColor

        // Provide data source to create items.
        dayMenuView.dataSource = dayMenu
        dayMenuView.textColor = Appearance.darkGrayTextColor
        // Update if possible. Observe. Commit if needed.
        dayMenuView.visibleItem = itemFromDate(event.startDate)
        if let view = dayMenuView.visibleItem {
            dayMenu.selectedItem = DayMenuItem.fromView(view)
            renderAccessibilityValueForElement(dayMenuView, value: nil)
        }
    }

    private func tearDownDayMenu() {}

    private func toggleDatePickerDrawerAppearance(visible: Bool? = nil,
                                                  customDelay: NSTimeInterval? = nil,
                                                  customDuration: NSTimeInterval? = nil,
                                                  customOptions: UIViewAnimationOptions? = nil,
                                                  completion: ((Bool) -> Void)? = nil) {
        let visible = visible ?? !isDatePickerDrawerExpanded
        guard visible != isDatePickerDrawerExpanded else {
            completion?(true)
            return
        }

        let delay = customDelay ?? 0
        let duration = customDuration ?? datePickerAppearanceDuration
        let options = customOptions ?? []
        func toggle() {
            datePickerDrawerHeightConstraint.constant = visible ? activeDatePicker.frame.height : 1
            dayLabelHeightConstraint.constant = visible ? 0 : initialDayLabelHeightConstant
            dayLabelTopEdgeConstraint.constant = visible ? 0 : initialDayLabelTopEdgeConstant
            view.animateLayoutChangesWithDuration(duration, options: options, completion: completion)
        }
        if visible {
            dispatchAfter(delay, block: toggle)
        } else {
            toggle()
        }

        isDatePickerDrawerExpanded = visible
    }

    private func toggleDayMenuCloak(visible: Bool) {
        if visible {
            dayMenuView.alpha = 0
        } else {
            UIView.animateWithDuration(0.3) { self.dayMenuView.alpha = 1 }
        }
    }

    private func toggleDrawerDatePickerAppearance() {
        func toggleDatePicker(datePicker: UIDatePicker, visible: Bool) {
            datePicker.hidden = !visible
            datePicker.enabled = visible
            datePicker.userInteractionEnabled = visible
        }
        switch activeDatePicker {
        case dayDatePicker:
            toggleDatePicker(dayDatePicker, visible: true)
            toggleDatePicker(timeDatePicker, visible: false)
        case timeDatePicker:
            toggleDatePicker(timeDatePicker, visible: true)
            toggleDatePicker(dayDatePicker, visible: false)
        default: fatalError("Unimplemented date picker.")
        }
    }

    private func updateDayLabel(date date: NSDate?) {
        defer {
            renderAccessibilityValueForElement(dayLabel, value: date)
        }
        guard let date = date else {
            dayLabel.text = nil
            return
        }
        dayLabel.text = NSDateFormatter.dateFormatter.stringFromDate(date).uppercaseString
    }

    // MARK: NavigationTitleScrollViewDelegate

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView,
                                   didChangeVisibleItem visibleItem: UIView) {
        guard let item = DayMenuItem.fromView(visibleItem) else { return }
        changeDayMenuItem(item)
    }

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView,
                                   didReceiveControlEvents controlEvents: UIControlEvents,
                                   forItem item: UIControl) {
        if controlEvents.contains(.TouchUpInside) && DayMenuItem.fromView(item) == .Later {
            toggleDayPicking(item)
        }
    }

}

// MARK: - Toolbar UI

extension EventViewController {

    private func setUpEditToolbar() {
        // Save initial state.
        initialToolbarBottomEdgeConstant = toolbarBottomEdgeConstraint.constant
        // Style toolbar itself.
        // NOTE: Not the same as setting in IB (which causes artifacts), for some reason.
        editToolbar.clipsToBounds = true
        // Set icons.
        timeItem.icon = .Clock
        locationItem.icon = .MapPin
        saveItem.icon = .CheckCircle
        if !event.isNew {
            toggleTimeItemFilled(event.startDate.hasCustomTime)
        }
    }

    private func toggleTimeItemFilled(on: Bool) {
        timeItem.toggleState(.Filled, on: on)
        renderAccessibilityValueForElement(timeItem, value: on)
    }

}
