//
//  FormFocusStateTests.swift
//  Eventual
//
//  Created by Peng Wang on 10/26/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

class FormFocusStateTests: XCTestCase {

    class TestFormFocusStateDelegate: NSObject, FormFocusStateDelegate {
        var focusedInputView: UIView?
        var previousFocusedInputView: UIView?
        var waitingSegueExpectation: XCTestExpectation?

        static let dismissalSegueIdentifier = "Dismissal-Segue"

        var isDebuggingInputState = false
        var shouldRefocus = true

        override init() {
            super.init()
        }
        func focusInputView(view: UIView, completionHandler: ((FormError?) -> Void)?) {
            self.focusedInputView = view
            completionHandler?(nil)
        }
        func blurInputView(view: UIView, withNextView nextView: UIView?, completionHandler: ((FormError?) -> Void)?) {
            self.previousFocusedInputView = view
            self.focusedInputView = nil
            completionHandler?(nil)
        }
        func shouldRefocusInputView(view: UIView, fromView currentView: UIView?) -> Bool {
            return self.shouldRefocus
        }
        func isDismissalSegue(identifier: String) -> Bool {
            return identifier == TestFormFocusStateDelegate.dismissalSegueIdentifier
        }
        func performWaitingSegueWithIdentifier(identifier: String, completionHandler: () -> Void) {
            dispatch_after(1.0) {
                completionHandler()
                self.waitingSegueExpectation?.fulfill()
            }
        }
        func shouldDismissalSegueWaitForInputView(view: UIView) -> Bool {
            return true
        }
    }

    var state: FormFocusState!
    var delegate: TestFormFocusStateDelegate!

    var anInputView = UIView(frame: CGRectZero)
    var anotherInputView = UIView(frame: CGRectZero)

    override func setUp() {
        super.setUp()

        self.delegate = TestFormFocusStateDelegate()
        self.state = FormFocusState(delegate: self.delegate)
    }

    override func tearDown() {
        super.tearDown()
    }

    func shiftToInputView(view: UIView?) {
        self.state.shiftToInputView(view)
        // Cleanup for synchronous calls.
        self.state.isShiftingToInputView = false
    }

    func testInitialization() {
        XCTAssertNil(self.state.currentInputView)
        XCTAssertNil(self.state.previousInputView)
    }

    func testShiftToInputView() {
        // Test initial switch:
        self.shiftToInputView(self.anInputView)
        XCTAssertEqual(self.state.currentInputView, self.anInputView, "Updates current input view state.")
        XCTAssertEqual(self.delegate.focusedInputView, self.anInputView, "Allows delegate to focus on input view.")
        // Test subsequent switch:
        self.shiftToInputView(self.anotherInputView)
        XCTAssertEqual(self.state.currentInputView, self.anotherInputView, "Updates current input view state.")
        XCTAssertEqual(self.delegate.previousFocusedInputView, self.anInputView, "Allows delegate to blur previous input view.")
        XCTAssertEqual(self.delegate.focusedInputView, self.anotherInputView, "Allows delegate to focus on input view.")
    }

    func testRefocusPreviousInputView() {
        // Given:
        self.shiftToInputView(self.anInputView)
        self.shiftToInputView(self.anotherInputView)
        // When:
        self.shiftToInputView(nil)
        // Then:
        XCTAssertNil(self.state.previousInputView, "Clears previous input view state.")
        XCTAssertEqual(self.state.currentInputView, self.anInputView, "Updates current input view state.")
        XCTAssertEqual(self.delegate.previousFocusedInputView, self.anotherInputView, "Allows delegate to blur previous input view.")

        // Given:
        self.shiftToInputView(self.anInputView)
        self.shiftToInputView(self.anotherInputView)
        // When:
        self.delegate.shouldRefocus = false
        self.shiftToInputView(nil)
        // Then:
        XCTAssertEqual(self.state.previousInputView, self.anotherInputView, "Clears previous input view state.")
        XCTAssertNil(self.state.currentInputView, "Unsets current input view state, without refocus.")
        XCTAssertEqual(self.delegate.previousFocusedInputView, self.anotherInputView, "Still allows delegate to blur previous input view.")
    }

    func testDismissalWithWaitingSegue() {
        // Test guarding:
        XCTAssertFalse(self.state.setupWaitingSegueForIdentifier(TestFormFocusStateDelegate.dismissalSegueIdentifier),
            "Needs to have current input view state.")
        self.shiftToInputView(anInputView)
        self.state.shouldGuardSegues = false
        XCTAssertFalse(self.state.setupWaitingSegueForIdentifier(TestFormFocusStateDelegate.dismissalSegueIdentifier),
            "Needs to be enabled.")
        self.state.shouldGuardSegues = true
        XCTAssertFalse(self.state.setupWaitingSegueForIdentifier("Some-Segue"),
            "Needs to be a dismissal segue identifier, per delegate.")
        // Given the above setup. Test.
        self.delegate.waitingSegueExpectation = self.expectationWithDescription("Segue will complete.")
        XCTAssertTrue(self.state.setupWaitingSegueForIdentifier(TestFormFocusStateDelegate.dismissalSegueIdentifier))
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        XCTAssertNil(self.state.currentInputView, "Unsets current input view state.")
    }

}
