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

    weak var currentSegue: UIStoryboardSegue?
    var unwindSegue: Segue?

    // MARK: EventScreen

    var event: Event! {
        didSet {
            guard isViewLoaded else { return }
            if isRestoringState { setUpData() }
            reloadData()
            if isRestoringState { validate() }
            isRestoringState = false
        }
    }

    func updateLocation(mapItem: MKMapItem?) {
        var value: String?
        if let address = mapItem?.placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
            value = address.joined(separator: "\n")
        }
        dataSource.changeFormData(value: value, for: #keyPath(Event.location))
    }

    // MARK: State

    fileprivate var didSaveEvent = false
    fileprivate var isRestoringState = false

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

    @IBOutlet private(set) var dayMenuView: TitlePickerView!
    fileprivate var dayMenu: DayMenuDataSource!

    // MARK: Interaction

    fileprivate var swipeDismissalTrait: ViewControllerSwipeDismissalTrait!

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAccessibility(specificElement: nil)

        // Setup subviews.
        resetSubviews()
        setUpDayMenu()
        setUpToolbar()

        if event != nil {
            setUpData()
            reloadData()
        }

        // Traits.
        swipeDismissalTrait = ViewControllerSwipeDismissalTrait(viewController: self) { [unowned self] in
            self.performSegue(withIdentifier: self.unwindSegue!.identifier, sender: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !isRestoringState else {
            performSegue(withIdentifier: unwindSegue!.identifier, sender: nil)
            return
        }

        descriptionView.setUpTopMask()
        updateLocationItem()

        let shouldFocus = event.isNew
        let shouldFocusDayDatePicker =
            event.startDate >= DayMenuItem.later.absoluteDate &&
            unwindSegue == .unwindToMonths
        if shouldFocus && !shouldFocusDayDatePicker {
            transitionFocus(to: descriptionView)
        }

        let updateDrawer = {
            self.drawerView.toggleToActiveDatePicker()
            self.updateDatePickerMinimums(for: self.event.startDate, withReset: false)
        }
        if !drawerView.isSetUp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.drawerView.setUp(form: self)
                self.drawerView.activeDatePicker = self.dayDatePicker
                self.setUpAccessibility(specificElement: self.drawerView)
                self.dataSource.initializeInputViewsWithFormDataObject()
                updateDrawer()
                if shouldFocus && shouldFocusDayDatePicker {
                    self.focusState.shiftInputView(to: self.drawerView.dayDatePicker)
                }
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

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        event.prepare()
        coder.encode(event, forKey: #keyPath(event))
        coder.encode(unwindSegue?.identifier, forKey: "unwindSegueIdentifier")
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        event = coder.decodeObject(forKey: #keyPath(event)) as! Event
        if let identifier = coder.decodeObject(forKey: "unwindSegueIdentifier") as? String {
            unwindSegue = Segue(rawValue: identifier)
        }
        isRestoringState = true
        var observer: NSObjectProtocol!
        observer = NotificationCenter.default.addObserver(forName: .EntityFetchOperation, object: nil, queue: nil) { _ in
            UIApplication.shared.sendAction(.restoreEvent, from: self)
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()
    }

    // MARK: - FormViewController

    // MARK: FormFocusStateDelegate

    override func shouldRefocus(to view: UIView, from currentView: UIView?) -> Bool {
        var should = super.shouldRefocus(to: view, from: currentView)

        if view === dayDatePicker && dayMenu.selectedItem != .later {
            should = false
        }

        return should
    }

    override func transitionFocus(to view: UIView?, from currentView: UIView? = nil,
                                  completion: (() -> Void)? = nil) {
        let isPicker = (from: currentView is UIDatePicker, to: view is UIDatePicker)
        let shouldToggleDrawer = isPicker.from || isPicker.to && !(isPicker.from && isPicker.to)
        var toggleDrawerDelay: TimeInterval?
        var toggleDrawerExpanded = false

        if let currentView = currentView {
            if isPicker.from {
                if currentView === timeDatePicker {
                    timeItem.toggle(state: .active, on: false)
                }
                toggleDrawerExpanded = false
            }
        }
        if let view = view {
            if isPicker.to, let view = view as? UIDatePicker {
                drawerView.activeDatePicker = view
                if view.isHidden {
                    drawerView.toggleToActiveDatePicker()
                }
                if view === timeDatePicker {
                    timeItem.toggle(state: .active, on: true)
                }
                toggleDrawerExpanded = true
            }
        }
        if shouldToggleDrawer {
            if currentView === descriptionView {
                toggleDrawerDelay = keyboardAnimationDuration
            }
            if !toggleDrawerExpanded {
                toggleDatePickerDrawer(expanded: false, customDelay: toggleDrawerDelay) { finished in
                    currentView?.resignFirstResponder()
                    view?.becomeFirstResponder()
                    completion?()
                }
            } else {
                currentView?.resignFirstResponder()
                toggleDatePickerDrawer(expanded: true, customDelay: toggleDrawerDelay) { finished in
                    view?.becomeFirstResponder()
                    completion?()
                }
            }
        } else {
            super.transitionFocus(to: view, from: currentView, completion: completion)
        }
    }

    override func isDismissalSegue(_ identifier: String) -> Bool {
        return identifier == dismissAfterSaveSegueIdentifier
    }

    override var dismissAfterSaveSegueIdentifier: String? {
        return unwindSegue?.identifier
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
            updateLocationItem()
            detailsView.updateTimeAndLocationLabel()
        }
        // Don't perform editInCalendarApp action, since data won't reflect (unsaved) changes.
        self.navigationItem.setRightBarButton(nil, animated: true)

        super.formDidChangeDataObject(value: value, for: keyPath)
    }

    override func formDidCommitValue(for inputView: UIView) {
        if drawerView.isSetUp && inputView === dayDatePicker {
            updateDayLabel(date: dayDatePicker.date)
        }
    }

    // MARK: Disabling

    override func toggleEnabled() {
        super.toggleEnabled()
        dayMenuView.isEnabled = isEnabled
        if let event = event, event.startDate.dayDate < Date().dayDate {
            dayMenuView.isHidden = true
            navigationItem.titleView = nil
            navigationItem.title = t("Event", "bar title").uppercased()
        }
    }

    // MARK: Submission

    override func completeEditing(_ sender: UIView) {
        guard event.hasChanges else { return }
        super.completeEditing(sender)
    }

    override func saveFormData() throws {
        try flowDataSource.save(event: event, commit: true)
        didSaveEvent = true
    }

    // MARK: - Sync w/ Keyboard

    override func willAnimateOnKeyboardAppearance(duration: TimeInterval, options: UIViewAnimationOptions) {
        toggleDatePickerDrawer(expanded: false, customDuration: duration, customOptions: options)
    }

    // MARK: UITextView Placeholder Text

    override func placeholder(forTextView textView: UITextView) -> String? {
        switch textView {
        case descriptionView: return t("Event title", "input placeholder")
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

    @objc private func showEventTimePicker(_ sender: Any?) {
        guard focusState.currentInputView !== timeDatePicker else { return }
        focusState.shiftInputView(to: timeDatePicker)
    }

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
        guard let identifier = unwindSegue?.identifier,
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
            titleScrollView(dayMenuView.scrollView, didChangeVisibleItem: laterItem)
        }
    }

    @IBAction private func editInCalendarApp(_ sender: UIBarButtonItem) {
        UIApplication.shared.sendAction(.showSystemEventEditor, from: self)
    }

    @IBAction private func handleLocationItemTap(_ sender: UIBarButtonItem) {
        locationItem.toggle(state: .active, on: true)
        UIApplication.shared.sendAction(.showEventLocation, from: self)
    }

    @IBAction private func toggleNavigationBar(_ swipeRecognizer: UISwipeGestureRecognizer) {
        let direction = swipeRecognizer.direction
        navigationController?.setNavigationBarHidden(direction == .up, animated: true)
        swipeRecognizer.direction = direction == .up ? .down : .up
    }

}

// MARK: - Data

extension EventViewController {

    fileprivate func clearEventEditsIfNeeded() {
        guard !event.isNew && !didSaveEvent else { return }
        event.resetChanges()
    }

    fileprivate func reloadData() {
        updateDayLabel(date: event.startDate.dayDate)
        if !event.isNew && event.entity != nil {
            event.entity.isAllDay = false // So time-picking works.
            isEnabled =
                event.calendar.allowsContentModifications &&
                event.startDate.dayDate >= Date().dayDate &&
                !event.entity.hasRecurrenceRules &&
                event.entity.organizer?.isCurrentUser != false
            isEnabledLocked = true
            if isEnabled && !detailsView.timeAndLocationLabel.isUserInteractionEnabled {
                detailsView.locationLabelAction = .showEventLocation
                detailsView.timeLabelAction = .showEventTimePicker
                detailsView.timeAndLocationLabel.actionSender = self
                detailsView.updateTimeAndLocationLabel()
            }
        }
        dataSource.initializeInputViewsWithFormDataObject()
    }

    fileprivate func setUpData() {
        if event.isNew {
            navigationItem.rightBarButtonItem = nil
        }

        // Update if possible. Observe. Commit if needed.
        dayMenuView.visibleItem = itemFromDate(event.startDate)
        if let view = dayMenuView.visibleItem {
            dayMenu.selectedItem = DayMenuItem.from(view: view)
            renderAccessibilityValue(for: dayMenuView, value: nil)
        }

        detailsView.event = event

        if !event.isNew {
            toggleTimeItem(filled: event.startDate.hasCustomTime)
        }
        updateLocationItem()
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === descriptionView else { return }
        descriptionView.toggleTopMask(visible: !descriptionView.shouldHideTopMask)
    }

    fileprivate func resetSubviews() {
        updateDayLabel(date: nil)
        descriptionView.text = nil
    }

}

// MARK: - Day Menu & Date Picker UI

extension EventViewController: TitleScrollViewDelegate {

    fileprivate func isDatePickerVisible(_ datePicker: UIDatePicker) -> Bool {
        return datePicker === drawerView.activeDatePicker && datePicker === focusState.currentInputView
    }

    fileprivate func setUpDayMenu() {
        dayMenu = DayMenuDataSource()
        dayMenuView.delegate = self
        dayMenuView.setUp()
        // Style day label and menu.
        dayLabel.textColor = Appearance.lightGrayTextColor
        // Provide data source to create items.
        dayMenuView.dataSource = dayMenu
        dayMenuView.textColor = Appearance.darkGrayTextColor
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
            toggleAlongside: nil,
            completion: { finished in
                completion?(finished)
                self.dayMenuView.isUserInteractionEnabled = true
            }
        )
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

    // MARK: TitleScrollViewDelegate

    func titleScrollViewContext(_ scrollView: TitleScrollView) -> String {
        return TitleScrollViewContext.navigationBar.rawValue
    }

    func titleScrollView(_ scrollView: TitleScrollView, didChangeVisibleItem visibleItem: UIView) {
        guard let item = DayMenuItem.from(view: visibleItem) else { return }
        shiftDayMenuItem(to: item)
    }

    func titleScrollView(_ scrollView: TitleScrollView,
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
    }

    fileprivate func toggleTimeItem(filled: Bool) {
        timeItem.toggle(state: .filled, on: filled)
        renderAccessibilityValue(for: timeItem, value: filled)
    }

    fileprivate func updateLocationItem() {
        if locationItem.state == .active {
            locationItem.toggle(state: .active, on: false)
        }
        let filled = event.hasLocation
        locationItem.toggle(state: .filled, on: filled)
        renderAccessibilityValue(for: locationItem, value: filled)
    }

}
