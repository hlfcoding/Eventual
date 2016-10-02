//
//  EventViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

import MapKit

final class EventViewController: FormViewController, EventScreen {

    // MARK: CoordinatedViewController

    weak var coordinator: NavigationCoordinatorProtocol?

    // MARK: EventScreen

    var unwindSegueIdentifier: String?
    var event: Event!

    func updateLocation(mapItem: MKMapItem) {
        guard let address = mapItem.placemark.addressDictionary?["FormattedAddressLines"] as? [String]
            else { return }
        dataSource.changeFormData(value: address.joined(separator: "\n"), for: #keyPath(Event.location))
    }

    // MARK: State

    fileprivate var didSaveEvent = false

    // MARK: Subviews & Appearance

    @IBOutlet private(set) var drawerView: EventDatePickerDrawerView!

    var dayDatePicker: UIDatePicker { return drawerView.dayDatePicker! }
    var timeDatePicker: UIDatePicker { return drawerView.timeDatePicker! }

    @IBOutlet private(set) var dayLabel: UILabel!
    @IBOutlet private(set) var descriptionView: MaskedTextView!

    @IBOutlet private(set) var detailsView: EventDetailsView!

    @IBOutlet private(set) var timeItem: IconBarButtonItem!
    @IBOutlet private(set) var locationItem: IconBarButtonItem!
    @IBOutlet private(set) var saveItem: IconBarButtonItem!

    @IBOutlet private(set) var dayMenuView: NavigationTitlePickerView!
    fileprivate var dayMenu: DayMenuDataSource!

    // MARK: Constraints & Related State

    @IBOutlet fileprivate var dayLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var dayLabelTopEdgeConstraint: NSLayoutConstraint!
    fileprivate var initialDayLabelHeightConstant: CGFloat!
    fileprivate var initialDayLabelTopEdgeConstant: CGFloat!

    // MARK: - Initializers

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    private func setUp() {
        customizeNavigationItem()
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAccessibility(specificElement: nil)

        guard unwindSegueIdentifier != nil else { preconditionFailure("Requires unwind segue identifier.") }
        guard navigationController != nil else { preconditionFailure("Requires a navigation bar.") }

        // isDebuggingInputState = true

        resetSubviews()

        // Setup subviews.
        setUpDayMenu()
        detailsView.event = event
        setUpToolbar()

        // Setup state.
        updateDayLabel(date: event.startDate.dayDate)
        if event.isNew {
            dataSource.initializeInputViewsWithFormDataObject()
        } else {
            event.isAllDay = false // So time-picking works.
            dataSource.initializeInputViewsWithFormDataObject()
            if isEnabled != event.calendar.allowsContentModifications {
                isEnabled = event.calendar.allowsContentModifications
                isEnabledLocked = true
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        toggleDayMenuCloak(visible: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        descriptionView.setUpTopMask()
        toggleDayMenuCloak(visible: false)

        if locationItem.state == .active {
            locationItem.toggle(state: .active, on: false)
        }
        if event.hasLocation {
            locationItem.toggle(state: .filled, on: true)
            renderAccessibilityValue(for: locationItem, value: true)
        }
        if event.isNew {
            transitionFocus(fromView: nil, toView: descriptionView, completion: nil)
        }

        let updateDrawer = {
            self.drawerView.toggleToActiveDatePicker()
            self.updateDatePickerMinimums(for: self.event.startDate, withReset: false)
        }
        if !drawerView.isSetUp {
            dispatchAfter(0.1) {
                self.drawerView.setUp(form: self)
                self.drawerView.activeDatePicker = self.dayDatePicker
                self.setUpAccessibility(specificElement: self.drawerView)
                self.dataSource.initializeInputViewsWithFormDataObject()
                updateDrawer()
            }
        } else {
            updateDrawer()
        }
    }

    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        if isDismissalSegue(identifier) {
            clearEventEditsIfNeeded()
        }
        super.performSegue(withIdentifier: identifier, sender: sender)
    }

    // MARK: - FormViewController

    // MARK: FormFocusStateDelegate

    override func shouldRefocus(toView: UIView, fromView currentView: UIView?) -> Bool {
        var should = super.shouldRefocus(toView: toView, fromView: currentView)

        if view === dayDatePicker && dayMenu.selectedItem != .later {
            should = false
        }

        return should
    }

    override func transitionFocus(fromView: UIView?, toView: UIView?,
                                  completion: (() -> Void)?) {
        let isPicker = (from: fromView is UIDatePicker, to: toView is UIDatePicker)
        let shouldToggleDrawer = isPicker.from || isPicker.to && !(isPicker.from && isPicker.to)
        var toggleDrawerDelay: TimeInterval?
        var toggleDrawerExpanded = false

        if let fromView = fromView {
            if isPicker.from {
                if fromView === timeDatePicker {
                    timeItem.toggle(state: .active, on: false)
                }
                toggleDrawerExpanded = false
            }
        }
        if let toView = toView {
            if isPicker.to, let toView = toView as? UIDatePicker {
                drawerView.activeDatePicker = toView
                if toView.isHidden {
                    drawerView.toggleToActiveDatePicker()
                }
                if toView === timeDatePicker {
                    timeItem.toggle(state: .active, on: true)
                }
                toggleDrawerExpanded = true
            }
        }
        if shouldToggleDrawer {
            if fromView === descriptionView {
                toggleDrawerDelay = keyboardAnimationDuration
            }
            if !toggleDrawerExpanded {
                toggleDatePickerDrawer(expanded: false, customDelay: toggleDrawerDelay) { finished in
                    fromView?.resignFirstResponder()
                    toView?.becomeFirstResponder()
                    completion?()
                }
            } else {
                fromView?.resignFirstResponder()
                toggleDatePickerDrawer(expanded: true, customDelay: toggleDrawerDelay) { finished in
                    toView?.becomeFirstResponder()
                    completion?()
                }
            }
        } else {
            super.transitionFocus(fromView: fromView, toView: toView, completion: completion)
        }
    }

    override func isDismissalSegue(_ identifier: String) -> Bool {
        return identifier == dismissAfterSaveSegueIdentifier
    }

    override var dismissAfterSaveSegueIdentifier: String? {
        return unwindSegueIdentifier
    }

    // MARK: FormDataSourceDelegate

    override var formDataObject: NSObject { return event }

    override var formDataValueToInputView: KeyPathsMap {
        return [
            #keyPath(Event.title): #keyPath(descriptionView),
            #keyPath(Event.startDate): [#keyPath(drawerView.dayDatePicker), #keyPath(drawerView.timeDatePicker)],
        ]
    }

    override func formInfo(for inputView: UIView) -> (name: String, valueKeyPath: String, emptyValue: Any) {
        let name: String!, valueKeyPath: String!, emptyValue: Any!
        if inputView === descriptionView {
            name = "Event Description"
            valueKeyPath = #keyPath(Event.title)
            emptyValue = ""
        } else if drawerView.isSetUp && (inputView === dayDatePicker || inputView === timeDatePicker) {
            switch inputView {
            case dayDatePicker: name = "Day Picker"
            case timeDatePicker: name = "Time Picker"
            default: fatalError("Unknown picker.")
            }
            valueKeyPath = #keyPath(Event.startDate)
            emptyValue = Date().dayDate
        } else {
            preconditionFailure("Unknown field.")
        }
        return (name, valueKeyPath, emptyValue)
    }

    override func formDidChangeDataObject<T>(value: T?, for keyPath: String) {
        if case keyPath = #keyPath(Event.startDate), let startDate = value as? Date {
            let filled = startDate.hasCustomTime
            if filled && timeItem.state == .active {
                // Suspend if needed.
                timeItem.toggle(state: .active, on: false)
            }
            toggleTimeItem(filled: filled)
            if !filled && isDatePickerVisible(timeDatePicker) {
                // Restore if needed.
                timeItem.toggle(state: .active, on: true)
            }

            if startDate != timeDatePicker.date {
                dataSource.setValue(startDate as Any, for: timeDatePicker)
                // Limit time picker if needed.
                updateDatePickerMinimums(for: startDate)
            }
            updateDayLabel(date: startDate)

            detailsView.updateTimeAndLocationLabel()

        } else if case keyPath = #keyPath(Event.location) {
            detailsView.updateTimeAndLocationLabel()
        }

        super.formDidChangeDataObject(value: value, for: keyPath)
    }

    override func formDidCommitValue(for inputView: UIView) {
        if drawerView.isSetUp && view === dayDatePicker {
            updateDayLabel(date: dayDatePicker.date)
        }
    }

    // MARK: Disabling

    override func toggleEnabled() {
        super.toggleEnabled()
        dayMenuView.isUserInteractionEnabled = isEnabled
    }

    // MARK: Submission

    override func saveFormData() throws {
        guard let coordinator = coordinator else { return }
        try coordinator.save(event: event)
        didSaveEvent = true
    }

    // MARK: - Sync w/ Keyboard

    override func willAnimateOnKeyboardAppearance(duration: TimeInterval, options: UIViewAnimationOptions) {
        toggleDatePickerDrawer(expanded: false, customDuration: duration, customOptions: options)
    }

    // MARK: UITextView Placeholder Text

    override func placeholder(forTextView textView: UITextView) -> String? {
        switch textView {
        case descriptionView: return t("Event", "input placeholder")
        default: return nil
        }
    }

    // MARK: Validation

    override func validateFormData() throws {
        try event.validate()
    }

    override func didValidateFormData() {
        let on = isValid
        saveItem.toggle(state: .successful, on: on)
        renderAccessibilityValue(for: saveItem, value: on)
    }

    // MARK: - Actions

    @IBAction fileprivate func toggleDayPicking(_ sender: UIView) {
        let shouldBlur = focusState.currentInputView === dayDatePicker
        focusState.shiftInputView(to: shouldBlur ? nil : dayDatePicker)
    }

    @IBAction private func toggleTimePicking(_ sender: UIBarButtonItem) {
        let shouldBlur = focusState.currentInputView === timeDatePicker
        focusState.shiftInputView(to: shouldBlur ? nil : timeDatePicker)
    }

    @IBAction private func dismissToPresentingViewController(_ sender: Any) {
        // Use the dismiss-after-save segue, but we're not saving.
        guard let identifier = unwindSegueIdentifier,
            shouldPerformSegue(withIdentifier: identifier, sender: self)
            else { return }
        performSegue(withIdentifier: identifier, sender: self)
    }

    @IBAction private func editDayDateFromDayLabel(_ tapRecognizer: UITapGestureRecognizer) {
        // TODO: Add itemFromIdentifier.
        guard isEnabled,
            let laterItemIndex = dayMenu.positionedItems.index(of: .later)
            else { return }

        let laterItem = dayMenuView.items[laterItemIndex]
        let needsManualUpdate = dayMenuView.visibleItem === laterItem

        dayMenuView.visibleItem = dayMenuView.items[laterItemIndex]

        if needsManualUpdate {
            navigationTitleScrollView(dayMenuView.scrollView, didChangeVisibleItem: laterItem)
        }
    }

    @IBAction private func handleLocationItemTap(_ sender: UIBarButtonItem) {
        locationItem.toggle(state: .active, on: true)
        coordinator?.performNavigationAction(for: .locationButtonTap, viewController: self)
    }

}

// MARK: - Data

extension EventViewController {

    fileprivate func clearEventEditsIfNeeded() {
        guard !event.isNew && !didSaveEvent else { return }
        event.resetChanges()
    }

    // MARK: Start Date

    fileprivate func shiftDayMenuItem(to item: DayMenuItem) {
        if let current = dayMenu.selectedItem, current != item && current == .later,
            let minimumDate = dayDatePicker.minimumDate {
            dayDatePicker.setDate(minimumDate, animated: false)
        }

        dayMenu.selectedItem = item
        renderAccessibilityValue(for: dayMenuView, value: nil)

        // Invalidate end date, then update start date.
        // NOTE: This manual update is an exception to FormViewController conventions.
        let dayDate = dateFromDayMenuItem(dayMenu.selectedItem!, withTime: false, asLatest: true)
        dataSource.changeFormData(value: dayDate, for: #keyPath(Event.startDate))

        let shouldFocus = dayMenu.selectedItem == .later
        let shouldBlur = !shouldFocus && focusState.currentInputView === dayDatePicker
        guard shouldFocus || shouldBlur else { return }

        focusState.shiftInputView(to: shouldBlur ? nil : dayDatePicker)
    }

    private func dateFromDayMenuItem(_ item: DayMenuItem, withTime: Bool = true,
                                     asLatest: Bool = true) -> Date {
        var date = item.absoluteDate
        // Account for time.
        if withTime {
            date = date.date(withTime: timeDatePicker.date)
        }
        // Return existing date if fitting when editing.
        let existingDate = event.startDate
        if asLatest && item == .later && date < existingDate {
            return existingDate
        }
        return date
    }

    fileprivate func itemFromDate(_ date: Date) -> UIView {
        let index = dayMenu.itemIndex(from: date)
        return dayMenuView.items[index]
    }

    fileprivate func updateDatePickerMinimums(for date: Date, withReset: Bool = true) {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let minimumDate = Date().hourDate(
                byAddingHours: calendar.component(.hour, from: Date()) == 23 ? 0 : 1
            )
            if withReset || date < minimumDate {
                timeDatePicker.setDate(minimumDate, animated: false)
            }
            timeDatePicker.minimumDate = minimumDate

        } else {
            timeDatePicker.minimumDate = nil
            if withReset {
                timeDatePicker.setDate(date.dayDate, animated: false)
            }
        }

        let minimumDate = dateFromDayMenuItem(.later, asLatest: false)
        if date < minimumDate {
            dayDatePicker.setDate(minimumDate, animated: false)
        }
        dayDatePicker.minimumDate = minimumDate
    }

}

// MARK: - Shared UI

extension EventViewController {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard scrollView === descriptionView else { return }
        descriptionView.toggleTopMask(visible: !descriptionView.shouldHideTopMask)
    }

    fileprivate func resetSubviews() {
        updateDayLabel(date: nil)
        descriptionView.text = nil
    }

}

// MARK: - Day Menu & Date Picker UI

extension EventViewController: NavigationTitleScrollViewDelegate {

    fileprivate func isDatePickerVisible(_ datePicker: UIDatePicker) -> Bool {
        return datePicker === drawerView.activeDatePicker && datePicker === focusState.currentInputView
    }

    fileprivate func setUpDayMenu() {
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
            dayMenu.selectedItem = DayMenuItem.from(view: view)
            renderAccessibilityValue(for: dayMenuView, value: nil)
        }
    }

    fileprivate func toggleDatePickerDrawer(expanded: Bool? = nil,
                                            customDelay: TimeInterval? = nil,
                                            customDuration: TimeInterval? = nil,
                                            customOptions: UIViewAnimationOptions? = nil,
                                            completion: ((Bool) -> Void)? = nil) {
        guard drawerView.isSetUp else { return }
        dayMenuView.isUserInteractionEnabled = false
        drawerView.toggle(
            expanded: expanded, customDelay: customDelay, customDuration: customDuration,
            customOptions: customOptions,
            toggleAlongside: { expanded in
                self.dayLabelHeightConstraint.constant = expanded ? 0 : self.initialDayLabelHeightConstant
                self.dayLabelTopEdgeConstraint.constant = expanded ? 0 : self.initialDayLabelTopEdgeConstant
            }, completion: { finished in
                completion?(finished)
                self.dayMenuView.isUserInteractionEnabled = true
            }
        )
    }

    fileprivate func toggleDayMenuCloak(visible: Bool) {
        if visible {
            dayMenuView.alpha = 0
        } else {
            UIView.animate(withDuration: 0.3) { self.dayMenuView.alpha = 1 }
        }
    }

    fileprivate func updateDayLabel(date: Date?) {
        defer {
            renderAccessibilityValue(for: dayLabel, value: date)
        }
        guard let date = date else {
            dayLabel.text = nil
            return
        }
        dayLabel.text = DateFormatter.dateFormatter.string(from: date).uppercased()
    }

    // MARK: NavigationTitleScrollViewDelegate

    func navigationTitleScrollView(_ scrollView: NavigationTitleScrollView,
                                   didChangeVisibleItem visibleItem: UIView) {
        guard let item = DayMenuItem.from(view: visibleItem) else { return }
        shiftDayMenuItem(to: item)
    }

    func navigationTitleScrollView(_ scrollView: NavigationTitleScrollView,
                                   didReceiveControlEvents controlEvents: UIControlEvents,
                                   forItem item: UIControl) {
        if controlEvents.contains(.touchUpInside) && DayMenuItem.from(view: item) == .later {
            toggleDayPicking(item)
        }
    }

}

// MARK: - Toolbar UI

extension EventViewController {

    fileprivate func setUpToolbar() {
        // Set icons.
        timeItem.icon = .clock
        locationItem.icon = .mapPin
        saveItem.icon = .checkCircle
        if !event.isNew {
            toggleTimeItem(filled: event.startDate.hasCustomTime)
        }
    }

    fileprivate func toggleTimeItem(filled: Bool) {
        timeItem.toggle(state: .filled, on: filled)
        renderAccessibilityValue(for: timeItem, value: filled)
    }

}
