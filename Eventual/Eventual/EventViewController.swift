//
//  EventViewController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit
import EventKit

@objc(ETEventViewController) class EventViewController: UIViewController {

    // MARK: State
    
    var event: EKEvent?
    var isDataValid: Bool = false
    
    // MARK: Subviews
    
    @IBOutlet private weak var datePicker: UIDatePicker!
    @IBOutlet private weak var dayLabel: UILabel!
    @IBOutlet private weak var descriptionView: UITextView!
    @IBOutlet private weak var descriptionContainerView: UIView!
    @IBOutlet private weak var editToolbar: UIToolbar!
    @IBOutlet private weak var timeItem: UIBarButtonItem!
    @IBOutlet private weak var locationItem: UIBarButtonItem!
    @IBOutlet private weak var saveItem: UIBarButtonItem!
    @IBOutlet private weak var dayMenuView: NavigationTitleScrollView!
    
    private var navigationButtonItems: [UIButton]!
    
    private lazy var errorMessageView: UIAlertView! = {
        let alertView = UIAlertView()
        alertView.delegate = self
        self.acknowledgeErrorButtonIndex = alertView.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
        return alertView
    }()

    // MARK: Constraints
    
    @IBOutlet private weak var datePickerDrawerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var toolbarBottomEdgeConstraint: NSLayoutConstraint!

    // MARK: Day Menu
    
    private var dayIdentifier: String? {
    didSet {
        if self.dayIdentifier != oldValue {
            self.toggleDatePickerDrawerAppearance(self.dayIdentifier == self.laterIdentifier)
        }
    }
    }
    private var todayIdentifier: String!
    private var tomorrowIdentifier: String!
    private var laterIdentifier: String!
    
    // MARK: Defines
    
    private let observedEventKeyPaths = [ "title", "startDate" ]
    private var observerContext = 0
    
    private var acknowledgeErrorButtonIndex: Int?
    
    // MARK: Helpers
    
    private lazy var dayFormatter: NSDateFormatter! = {
        let dayFormatter = NSDateFormatter()
        dayFormatter.dateFormat = "MMMM d, y · EEEE"
        return dayFormatter
    }()

    private let eventManager = EventManager.defaultManager()

    // MARK: Initializers
    
    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setUp()
    }
    init(coder aDecoder: NSCoder!) {
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
        self.tearDown()
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetSubviews()
        self.setUpNewEvent()
    }
    
    // MARK: Handlers
    
    private func updateOnKeyboardAppearanceWithNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject] {
            let duration: NSTimeInterval = userInfo[UIKeyboardAnimationDurationUserInfoKey]! as NSTimeInterval
            var constant: Float = 0.0
            if notification.name == UIKeyboardWillShowNotification {
                let frame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as NSValue).CGRectValue()
                constant = Float((frame.size.height > frame.size.width) ? frame.size.width : frame.size.height)
            }
        }
    }
    
}

extension EventViewController { // MARK: Data
    
    private func setUpEvent() {
        if let event = self.event {
            for keyPath in self.observedEventKeyPaths {
                event.addObserver(self, forKeyPath: keyPath, options: .Initial | .New | .Old, context: &self.observerContext)
            }
        }
    }
    private func setUpNewEvent() {
        if self.event { return }
        self.event = EKEvent(eventStore: self.eventManager.store)
        self.setUpEvent()
    }
    
    private func tearDownEvent() {
        if let event = self.event {
            for keyPath in self.observedEventKeyPaths {
                event.removeObserver(self, forKeyPath: keyPath, context: &self.observerContext)
            }
        }
    }
    
    private func saveData() {
        if let event = self.event {
            var error: NSError?
            let didSave = self.eventManager.saveEvent(event, error: &error)
            let identifier = ETSegue.DismissToMonths.toRaw()
            if !didSave {
                self.toggleErrorMessage(true)
            } else if self.shouldPerformSegueWithIdentifier(identifier, sender: self) {
                self.performSegueWithIdentifier(identifier, sender: self)
            }
        }
    }
    
    private func validateData() {
        if let event = self.event {
            var error: NSError?
            self.isDataValid = self.eventManager.validateEvent(event, error: &error)
        }
    }
    
    private func dateFromDayIdentifier(identifier: String) -> NSDate {
        var date = NSDate.date()
        // MARK: Continue
        return date
    }
    
}

extension EventViewController { // MARK: Main UI
    
    private func resetSubviews() {
        self.dayLabel.text = nil
        self.descriptionView.text = nil
    }
    
    private func setUpDayMenu() {
        // Define.
        self.todayIdentifier = NSLocalizedString("Today", comment: "")
        self.tomorrowIdentifier = NSLocalizedString("Tomorrow", comment: "")
        self.laterIdentifier = NSLocalizedString("Later", comment: "")
        self.dayMenuView.accessibilityLabel = NSLocalizedString(ETLabel.EventScreenTitle.toRaw(), comment: "")
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
            if (identifier == self.laterIdentifier) {
                // Later item.
                if let button = item as? UIButton {
                    button.addTarget(self, action: "toggleDatePicking", forControlEvents: .TouchUpInside)
                }
                self.datePicker.minimumDate = self.dateFromDayIdentifier(self.laterIdentifier)
            }
        }
        // Observe.
        self.dayMenuView.addObserver(self, forKeyPath: "visibleItem", options: .New | .Old, context: &self.observerContext)
        // Commit.
        self.dayMenuView.processItems()
    }
    
    private func toggleDatePickerDrawerAppearance(visible: Bool) {
        // MARK: Continue
    }
    
    // MARK: Continue
}

extension EventViewController { // MARK: Error UI
    
    private func toggleErrorMessage(visible: Bool) {
        if visible {
            self.errorMessageView.show()
        } else {
            self.errorMessageView.dismissWithClickedButtonIndex(self.acknowledgeErrorButtonIndex!, animated: true)
        }
    }
    
}