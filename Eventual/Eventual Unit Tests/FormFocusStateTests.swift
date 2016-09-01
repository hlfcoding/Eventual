//
//  FormFocusStateTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class FormFocusStateTests: XCTestCase {

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

        func shouldRefocusInputView(view: UIView, fromView currentView: UIView?) -> Bool {
            return shouldRefocus
        }

        func transitionFocusFromInputView(source: UIView?, toInputView destination: UIView?,
                                          completionHandler: (() -> Void)?) {
            previousFocusedInputView = source
            focusedInputView = destination
            completionHandler?()
        }

        func isDismissalSegue(identifier: String) -> Bool {
            return identifier == TestFormFocusStateDelegate.dismissalSegueIdentifier
        }

        func performWaitingSegueWithIdentifier(identifier: String, completionHandler: () -> Void) {
            dispatchAfter(1) {
                completionHandler()
                self.waitingSegueExpectation?.fulfill()
            }
        }

        func shouldDismissalSegueWaitForInputView(view: UIView) -> Bool {
            return true
        }

    }

    lazy var anInputView = UIView(frame: CGRectZero)
    lazy var anotherInputView = UIView(frame: CGRectZero)

    var delegate: TestFormFocusStateDelegate!
    var state: FormFocusState!

    override func setUp() {
        super.setUp()
        delegate = TestFormFocusStateDelegate()
        state = FormFocusState(delegate: delegate)
    }

    func shiftToInputView(view: UIView?) {
        state.shiftToInputView(view)
        // Cleanup for synchronous calls.
        state.isShiftingToInputView = false
    }

    func testInitialization() {
        XCTAssertNil(state.currentInputView)
        XCTAssertNil(state.previousInputView)
    }

    func testShiftToInputView() {
        // Test initial switch:
        shiftToInputView(anInputView)
        XCTAssertEqual(state.currentInputView, anInputView, "Updates current input view state.")
        XCTAssertEqual(delegate.focusedInputView, anInputView, "Allows delegate to focus on input view.")
        // Test subsequent switch:
        shiftToInputView(anotherInputView)
        XCTAssertEqual(state.currentInputView, anotherInputView, "Updates current input view state.")
        XCTAssertEqual(delegate.previousFocusedInputView, anInputView, "Allows delegate to blur previous input view.")
        XCTAssertEqual(delegate.focusedInputView, anotherInputView, "Allows delegate to focus on input view.")
    }

    func testRefocusPreviousInputView() {
        // Given:
        shiftToInputView(anInputView)
        shiftToInputView(anotherInputView)
        // When:
        shiftToInputView(nil)
        // Then:
        XCTAssertNil(state.previousInputView, "Clears previous input view state.")
        XCTAssertEqual(state.currentInputView, anInputView, "Updates current input view state.")
        XCTAssertEqual(delegate.previousFocusedInputView, anotherInputView, "Allows delegate to blur previous input view.")

        // Given:
        shiftToInputView(anInputView)
        shiftToInputView(anotherInputView)
        // When:
        delegate.shouldRefocus = false
        shiftToInputView(nil)
        // Then:
        XCTAssertEqual(state.previousInputView, anotherInputView, "Clears previous input view state.")
        XCTAssertNil(state.currentInputView, "Unsets current input view state, without refocus.")
        XCTAssertEqual(delegate.previousFocusedInputView, anotherInputView, "Still allows delegate to blur previous input view.")
    }

    func testDismissalWithWaitingSegue() {
        // Test guarding:
        XCTAssertFalse(state.setupWaitingSegueForIdentifier(TestFormFocusStateDelegate.dismissalSegueIdentifier),
            "Needs to have current input view state.")
        shiftToInputView(anInputView)
        state.shouldGuardSegues = false
        XCTAssertFalse(state.setupWaitingSegueForIdentifier(TestFormFocusStateDelegate.dismissalSegueIdentifier),
            "Needs to be enabled.")
        state.shouldGuardSegues = true
        XCTAssertFalse(state.setupWaitingSegueForIdentifier("Some-Segue"),
            "Needs to be a dismissal segue identifier, per delegate.")
        // Given the above setup. Test.
        delegate.waitingSegueExpectation = expectationWithDescription("Segue will complete.")
        XCTAssertTrue(state.setupWaitingSegueForIdentifier(TestFormFocusStateDelegate.dismissalSegueIdentifier))
        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertNil(state.currentInputView, "Unsets current input view state.")
    }

}
