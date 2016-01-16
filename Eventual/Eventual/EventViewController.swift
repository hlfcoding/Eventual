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

import MapKit
import HLFMapViewController

class EventViewController: FormViewController {

    var unwindSegueIdentifier: Segue?

    // MARK: State

    var event: EKEvent!
    var newEventStartDate: NSDate!

    func changeDayIdentifier(identifier: String?, autoFocus: Bool = true) {
        guard self.dayMenu.dayIdentifier != identifier else { return }
        self.dayMenu.dayIdentifier = identifier

        // Invalidate end date, then update start date.
        // NOTE: This manual update is an exception to FormViewController conventions.
        let dayDate = self.dateFromDayIdentifier(self.dayMenu.dayIdentifier!, withTime: false, asLatest: true)
        self.dataSource.changeFormDataValue(dayDate, atKeyPath: "startDate")

        let shouldFocus = autoFocus && self.dayMenu.dayIdentifier == self.dayMenu.laterIdentifier
        let shouldBlur = !shouldFocus && self.focusState.currentInputView == self.dayDatePicker
        guard shouldFocus || shouldBlur else { return }

        self.focusState.shiftToInputView(shouldBlur ? nil : self.dayDatePicker)
    }

    private var isEditingEvent: Bool {
        guard let event = self.event else { return false }
        return !event.eventIdentifier.isEmpty
    }

    private var didSaveEvent = false

    private var selectedMapItem: MKMapItem?

    // MARK: Subviews & Appearance

    @IBOutlet private var dayDatePicker: UIDatePicker!
    @IBOutlet private var timeDatePicker: UIDatePicker!
    // NOTE: This doesn't correlate with picker visibility.
    private weak var activeDatePicker: UIDatePicker!

    @IBOutlet private var dayLabel: UILabel!
    @IBOutlet private var descriptionView: MaskedTextView!

    @IBOutlet private var detailsView: EventDetailsView!

    @IBOutlet private var editToolbar: UIToolbar!
    @IBOutlet private var timeItem: IconBarButtonItem!
    @IBOutlet private var locationItem: IconBarButtonItem!
    @IBOutlet private var saveItem: IconBarButtonItem!

    @IBOutlet private var dayMenuView: NavigationTitlePickerView!
    private var dayMenu: DayMenuDataSource!

    private lazy var errorViewController: UIAlertController! = {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        alertController.addAction(
            UIAlertAction(title: t("OK"), style: .Default, handler: { (action) in self.toggleErrorPresentation(false) })
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

    private lazy var dayFormatter: NSDateFormatter! = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM d, y · EEEE"
        return formatter
    }()

    private lazy var timeFormatter: NSDateFormatter! = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private var eventManager: EventManager { return EventManager.defaultManager }
    private var appearanceManager: AppearanceManager { return AppearanceManager.defaultManager }

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
        self.customizeNavigationItem()

        self.newEventStartDate = NSDate().dayDate!

        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: Selector("updateOnKeyboardAppearanceWithNotification:"), name: UIKeyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: Selector("updateOnKeyboardAppearanceWithNotification:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    private func tearDown() {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
        self.tearDownDayMenu()
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        guard self.unwindSegueIdentifier != nil else { fatalError("Requires unwind segue identifier.") }
        guard self.navigationController != nil else { fatalError("Requires being a navigation bar.") }

        //self.isDebuggingInputState = true

        self.resetSubviews()

        // Setup data.
        self.setUpNewEventIfNeeded()

        // Setup subviews.
        self.setUpDayMenu()
        self.descriptionView.setUpTopMask()
        self.detailsView.event = self.event
        self.setUpEditToolbar()

        // Setup state: 1.
        self.activeDatePicker = self.dayDatePicker
        self.toggleDrawerDatePickerAppearance()

        // Setup state: 2.
        if self.isEditingEvent {
            self.event.allDay = false // So time-picking works.
            self.dataSource.initializeInputViewsWithFormDataObject()

        } else { // New event.
            self.dataSource.initializeInputViewsWithFormDataObject()
            self.changeDayIdentifier(self.dayMenu.identifierFromItem(self.dayMenuView.visibleItem), autoFocus: false)
            self.focusInputView(self.descriptionView, completionHandler: nil)
        }

        // Setup state: 3.
        self.updateDatePickerMinimumsForDate(withReset: false)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.toggleDayMenuCloak(true)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.toggleDayMenuCloak(false)

        if self.locationItem.state == .Active {
            self.locationItem.toggleState(.Active, on: false)
        }
        if self.event.hasLocation {
            self.locationItem.toggleState(.Filled, on: true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.descriptionView.updateTopMask()
    }

    override func performSegueWithIdentifier(identifier: String, sender: AnyObject?) {
        if self.isDismissalSegue(identifier) {
            self.clearEventEditsIfNeeded()
        }
        super.performSegueWithIdentifier(identifier, sender: sender)
    }

    // MARK: - FormViewController

    // MARK: FormFocusStateDelegate

    override func focusInputView(view: UIView, completionHandler: ((FormError?) -> Void)?) {
        let isToPicker = view is UIDatePicker
        let isFromPicker = self.focusState.previousInputView is UIDatePicker
        let shouldToggleDrawer = isToPicker || isFromPicker && !(isToPicker && isFromPicker)

        if isToPicker {
            self.activeDatePicker = view as! UIDatePicker
            if self.activeDatePicker.hidden {
                self.toggleDrawerDatePickerAppearance()
            }
            if view == self.timeDatePicker {
                self.timeItem.toggleState(.Active, on: true)
            }
        }

        if shouldToggleDrawer {
            // NOTE: Redundancy ok.
            var customDelay = 0.0
            let shouldDelay = isToPicker && self.focusState.previousInputView === self.descriptionView
            if shouldDelay, let duration = self.keyboardAnimationDuration {
                customDelay = duration
            }
            self.toggleDatePickerDrawerAppearance(isToPicker, customDelay: customDelay) { (finished) in
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
            self.activeDatePicker = nextView as! UIDatePicker
            if self.activeDatePicker.hidden {
                self.toggleDrawerDatePickerAppearance()
            }
        }
        if isFromPicker {
            if view == self.timeDatePicker {
                self.timeItem.toggleState(.Active, on: false)
            }
        }

        if shouldToggleDrawer {
            // NOTE: Redundancy ok.
            var customDelay = 0.0
            let shouldDelay = isToPicker && view === self.descriptionView
            if shouldDelay, let duration = self.keyboardAnimationDuration {
                customDelay = duration
            }
            self.toggleDatePickerDrawerAppearance(isToPicker, customDelay: customDelay) { (finished) in
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

        if view == self.dayDatePicker && self.dayMenu.dayIdentifier != self.dayMenu.laterIdentifier {
            should = false
        }

        return should
    }

    override func isDismissalSegue(identifier: String) -> Bool {
        return identifier == self.dismissAfterSaveSegueIdentifier
    }

    override var dismissAfterSaveSegueIdentifier: String? {
        return self.unwindSegueIdentifier?.rawValue
    }

    // MARK: FormDataSourceDelegate

    override var formDataObject: NSObject { return self.event }

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
        default: fatalError("Unknown field.")
        }
        return (name, valueKeyPath, emptyValue)
    }

    override func formDidChangeDataObjectValue(value: AnyObject?, atKeyPath keyPath: String) {
        if case keyPath = "startDate",
           let startDate = value as? NSDate
        {
            let filled = startDate.hasCustomTime
            if filled && self.timeItem.state == .Active {
                // Suspend if needed.
                self.timeItem.toggleState(.Active, on: false)
            }
            self.timeItem.toggleState(.Filled, on: filled)
            if !filled && self.isDatePickerVisible(self.timeDatePicker)  {
                // Restore if needed.
                self.timeItem.toggleState(.Active, on: true)
            }

            if startDate != self.timeDatePicker.date {
                self.dataSource.setValue(startDate, forInputView: self.timeDatePicker)
                // Limit time picker if needed.
                self.updateDatePickerMinimumsForDate(startDate)
            }

            let dayText = self.dayFormatter.stringFromDate(startDate)
            self.dayLabel.text = dayText.uppercaseString

            self.detailsView.updateTimeAndLocationLabelAnimated()

        } else if case keyPath = "location" {
            self.detailsView.updateTimeAndLocationLabelAnimated()
        }

        super.formDidChangeDataObjectValue(value, atKeyPath: keyPath)
    }

    override func formDidCommitValueForInputView(view: UIView) {
        switch view {
        case self.dayDatePicker:
            let date = (view as! UIDatePicker).date
            let dayText = self.dayFormatter.stringFromDate(date)
            self.dayLabel.text = dayText.uppercaseString
        default: break
        }
    }

    // MARK: Submission

    override func saveFormData() throws {
        try self.eventManager.saveEvent(self.event)
        self.didSaveEvent = true
    }

    override func didReceiveErrorOnFormSave(error: NSError) {
        guard let userInfo = error.userInfo as? [String: String] else { return }

        let description = userInfo[NSLocalizedDescriptionKey] ?? t("Unknown Error")
        let failureReason = userInfo[NSLocalizedFailureReasonErrorKey] ?? ""
        let recoverySuggestion = userInfo[NSLocalizedRecoverySuggestionErrorKey] ?? ""

        self.errorViewController.title = description.capitalizedString
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            .stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet())
        self.errorViewController.message = "\(failureReason) \(recoverySuggestion)"
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }

    // MARK: Validation

    override func validateFormData() throws {
        try self.eventManager.validateEvent(self.event)
    }

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

    // MARK: - Actions

    @IBAction private func toggleDayPicking(sender: UIView) {
        let shouldBlur = self.focusState.currentInputView == self.dayDatePicker
        self.focusState.shiftToInputView(shouldBlur ? nil : self.dayDatePicker)
    }

    @IBAction private func toggleTimePicking(sender: UIBarButtonItem) {
        let shouldBlur = self.focusState.currentInputView == self.timeDatePicker
        self.focusState.shiftToInputView(shouldBlur ? nil : self.timeDatePicker)
    }

    @IBAction private func dismissToPresentingViewController(sender: AnyObject) {
        // Use the dismiss-after-save segue, but we're not saving.
        guard let identifier = self.unwindSegueIdentifier?.rawValue
              where self.shouldPerformSegueWithIdentifier(identifier, sender: self)
              else { return }
        self.performSegueWithIdentifier(identifier, sender: self)
    }

    @IBAction private func startLocationPicking(sender: UIBarButtonItem) {
        self.locationItem.toggleState(.Active, on: true)

        let presentModalViewController = {
            let modal = NavigationController.modalMapViewControllerWithDelegate(self, selectedMapItem: self.selectedMapItem)
            self.presentViewController(modal, animated: true, completion: nil)
        }

        guard self.isEditingEvent && self.selectedMapItem == nil
              else { presentModalViewController(); return }

        self.event.fetchLocationPlacemarkIfNeeded { (placemarks, error) in
            guard error == nil else { print(error); return }
            guard let placemark = placemarks?.first else { return } // Location could not be geocoded.

            self.selectedMapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            presentModalViewController()
        }
    }

    @IBAction private func dismissModalMapViewController(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Handlers

    func updateOnKeyboardAppearanceWithNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject] else { return }

        let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
        self.keyboardAnimationDuration = duration
        let options = UIViewAnimationOptions(rawValue: userInfo[UIKeyboardAnimationCurveUserInfoKey]! as! UInt)
        var constant = 0.0 as CGFloat

        if notification.name == UIKeyboardWillShowNotification {
            let frame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
            constant = (frame.size.height > frame.size.width) ? frame.size.width : frame.size.height
            self.toggleDatePickerDrawerAppearance(false, customDuration: duration, customOptions: options)
        }

        self.toolbarBottomEdgeConstraint.constant = constant + self.initialToolbarBottomEdgeConstant
        self.editToolbar.animateLayoutChangesWithDuration(duration, usingSpring: false, options: options, completion: nil)
    }

}

// MARK: - Data

extension EventViewController {

    private func setUpNewEventIfNeeded() {
        guard !self.isEditingEvent else { return }
        self.event = EKEvent(eventStore: self.eventManager.store)
        self.event.startDate = self.newEventStartDate
    }

    private func clearEventEditsIfNeeded() {
        guard self.isEditingEvent && !self.didSaveEvent else { return }
        self.eventManager.resetEvent(self.event)
    }

    private func dateFromDayIdentifier(identifier: String, withTime: Bool = true, asLatest: Bool = true) -> NSDate {
        var date = self.dayMenu.dateFromDayIdentifier(identifier)
        // Account for time.
        if withTime {
            date = date.dateWithTime(self.timeDatePicker.date)
        }
        // Return existing date if fitting when editing.
        let existingDate = self.event.startDate
        if asLatest && identifier == self.dayMenu.laterIdentifier &&
           existingDate.laterDate(date) == existingDate
        {
            return existingDate
        }
        return date
    }

    private func itemFromDate(date: NSDate) -> UIView {
        let index = self.dayMenu.indexFromDate(date)
        return self.dayMenuView.items[index]
    }

    private func updateDatePickerMinimumsForDate(var date: NSDate? = nil, withReset: Bool = true) {
        date = date ?? self.event.startDate
        guard let date = date else { return }

        let calendar = NSCalendar.currentCalendar()
        if calendar.isDateInToday(date) {
            let date = NSDate()
            self.timeDatePicker.minimumDate = date.hourDateFromAddingHours(
                calendar.component(.Hour, fromDate: date) == 23 ? 0 : 1
            )
        } else {
            self.timeDatePicker.minimumDate = nil
            if withReset {
                self.timeDatePicker.date = date.dayDate!
            }
        }

        self.dayDatePicker.minimumDate = self.dateFromDayIdentifier(self.dayMenu.laterIdentifier, asLatest: false)
    }

}

// MARK: - Shared UI

extension EventViewController {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard scrollView == self.descriptionView else { return }
        self.descriptionView.toggleTopMask(!self.descriptionView.shouldHideTopMask)
    }

    private func resetSubviews() {
        self.dayLabel.text = nil
        self.descriptionView.text = nil
    }

}

// MARK: - Day Menu & Date Picker UI

extension EventViewController : NavigationTitleScrollViewDataSource, NavigationTitleScrollViewDelegate {

    private func isDatePickerVisible(datePicker: UIDatePicker) -> Bool {
        return datePicker == self.activeDatePicker && datePicker == self.focusState.currentInputView
    }

    private func setUpDayMenu() {
        self.dayMenu = DayMenuDataSource()
        self.dayMenuView.delegate = self
        // Save initial state.
        self.initialDayLabelHeightConstant = self.dayLabelHeightConstraint.constant
        self.initialDayLabelTopEdgeConstant = self.dayLabelTopEdgeConstraint.constant
        // Style day label and menu.
        self.dayLabel.textColor = self.appearanceManager.lightGrayTextColor
        self.dayMenuView.accessibilityLabel = t(Label.EventScreenTitle.rawValue)
        // Provide data source to create items.
        self.dayMenuView.dataSource = self
        // Update if possible. Observe. Commit if needed.
        self.dayMenuView.visibleItem = self.itemFromDate(self.event.startDate)
    }

    private func tearDownDayMenu() {}

    private func toggleDatePickerDrawerAppearance(visible: Bool? = nil,
                                                  customDelay: NSTimeInterval? = nil,
                                                  customDuration: NSTimeInterval? = nil,
                                                  customOptions: UIViewAnimationOptions? = nil,
                                                  completion: ((Bool) -> Void)? = nil)
    {
        let visible = visible ?? !self.isDatePickerDrawerExpanded
        guard visible != self.isDatePickerDrawerExpanded else { completion?(true); return }

        let delay = customDelay ?? 0.0
        let duration = customDuration ?? self.datePickerAppearanceDuration
        let options = customOptions ?? .CurveEaseInOut
        func toggle() {
            self.datePickerDrawerHeightConstraint.constant = visible ? self.activeDatePicker.frame.size.height : 1.0
            self.dayLabelHeightConstraint.constant = visible ? 0.0 : self.initialDayLabelHeightConstant
            self.dayLabelTopEdgeConstraint.constant = visible ? 0.0 : self.initialDayLabelTopEdgeConstant
            self.view.animateLayoutChangesWithDuration(duration, options: options, completion: completion)
        }
        if visible {
            dispatch_after(delay, block: toggle)
        } else {
            toggle()
        }

        self.isDatePickerDrawerExpanded = visible
    }

    private func toggleDayMenuCloak(visible: Bool) {
        if visible {
            self.dayMenuView.alpha = 0.0
        } else {
            UIView.animateWithDuration(0.3) { self.dayMenuView.alpha = 1.0 }
        }
    }

    private func toggleDrawerDatePickerAppearance() {
        func toggleDatePicker(datePicker: UIDatePicker, visible: Bool) {
            datePicker.hidden = !visible
            datePicker.userInteractionEnabled = visible
        }
        switch self.activeDatePicker {
        case self.dayDatePicker:
            toggleDatePicker(self.dayDatePicker, visible: true)
            toggleDatePicker(self.timeDatePicker, visible: false)
        case self.timeDatePicker:
            toggleDatePicker(self.timeDatePicker, visible: true)
            toggleDatePicker(self.dayDatePicker, visible: false)
        default: fatalError("Unimplemented date picker.")
        }
    }

    // MARK: NavigationTitleScrollViewDataSource

    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int {
        return self.dayMenu.orderedIdentifiers.count
    }

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView? {
        // For each item, decide type, then add and configure
        let (type, identifier) = self.dayMenu.itemAtIndex(index)
        guard let item = self.dayMenuView.newItemOfType(type, withText: identifier) else { return nil }

        item.accessibilityLabel = NSString.localizedStringWithFormat(t(Label.FormatDayOption.rawValue), identifier) as String

        if identifier == self.dayMenu.laterIdentifier, let button = item as? UIButton {
            button.addTarget(self, action: "toggleDayPicking:", forControlEvents: .TouchUpInside)
        }

        return item
    }

    // MARK: NavigationTitleScrollViewDelegate

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, didChangeVisibleItem visibleItem: UIView) {
        self.changeDayIdentifier(self.dayMenu.identifierFromItem(visibleItem))
    }

}

// MARK: - Toolbar UI

extension EventViewController {

    private func setUpEditToolbar() {
        // Save initial state.
        self.initialToolbarBottomEdgeConstant = self.toolbarBottomEdgeConstraint.constant
        // Style toolbar itself.
        // NOTE: Not the same as setting in IB (which causes artifacts), for some reason.
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

// MARK: - Location Picking

extension EventViewController: MapViewControllerDelegate {

    func mapViewController(mapViewController: MapViewController, didSelectMapItem mapItem: MKMapItem) {
        if let address = mapItem.placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
            self.dataSource.changeFormDataValue(address.joinWithSeparator("\n"), atKeyPath: "location")
        }

        self.selectedMapItem = mapItem
        self.dismissModalMapViewController(self)
    }

    func resultsViewController(resultsViewController: SearchResultsViewController,
                               didConfigureResultViewCell cell: SearchResultsViewCell, withMapItem mapItem: MKMapItem)
    {
        // NOTE: Regarding custom cell select and highlight background color, it
        // would still not match other cells' select behaviors. The only chance of
        // getting consistency seems to be copying the extensions in CollectionViewTileCell
        // to a SearchResultsViewCell subclass. This would also require references
        // for contentView edge constraints, and allow cell class to be customized.

        var customMargins = cell.contentView.layoutMargins
        customMargins.top = 20.0
        customMargins.bottom = 20.0
        cell.contentView.layoutMargins = customMargins
        resultsViewController.tableView.rowHeight = 60.0

        cell.customTextLabel.font = UIFont.systemFontOfSize(17.0)
    }

}
