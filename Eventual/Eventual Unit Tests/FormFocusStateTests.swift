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

        var shouldRefocus = true

        override init() {
            super.init()
        }

        func shouldRefocus(to view: UIView, from currentView: UIView?) -> Bool {
            return shouldRefocus
        }

        func transitionFocus(to view: UIView?, from currentView: UIView? = nil, completion: (() -> Void)? = nil) {
            previousFocusedInputView = currentView
            focusedInputView = view
            completion?()
        }

        func isDismissalSegue(_ identifier: String) -> Bool {
            return identifier == TestFormFocusStateDelegate.dismissalSegueIdentifier
        }

        func performWaitingSegue(_ identifier: String, completion: @escaping () -> Void) {
            dispatchAfter(1) {
                completion()
                self.waitingSegueExpectation?.fulfill()
            }
        }

        func shouldDismissalSegueWait(for inputView: UIView) -> Bool {
            return true
        }

    }

    lazy var anInputView = UIView(frame: .zero)
    lazy var anotherInputView = UIView(frame: .zero)

    var delegate: TestFormFocusStateDelegate!
    var state: FormFocusState!

    override func setUp() {
        super.setUp()
        delegate = TestFormFocusStateDelegate()
        state = FormFocusState(delegate: delegate)
    }

    func shiftInputView(to view: UIView?) {
        state.shiftInputView(to: view)
        // Cleanup for synchronous calls.
        state.isShiftingToInputView = false
    }

    func testInitialization() {
        XCTAssertNil(state.currentInputView)
        XCTAssertNil(state.previousInputView)
    }

    func testShiftToInputView() {
        // Test initial switch:
        shiftInputView(to: anInputView)
        XCTAssertEqual(state.currentInputView, anInputView, "Updates current input view state.")
        XCTAssertEqual(delegate.focusedInputView, anInputView, "Allows delegate to focus on input view.")
        // Test subsequent switch:
        shiftInputView(to: anotherInputView)
        XCTAssertEqual(state.currentInputView, anotherInputView, "Updates current input view state.")
        XCTAssertEqual(delegate.previousFocusedInputView, anInputView, "Allows delegate to blur previous input view.")
        XCTAssertEqual(delegate.focusedInputView, anotherInputView, "Allows delegate to focus on input view.")
    }

    func testRefocusPreviousInputView() {
        // Given:
        shiftInputView(to: anInputView)
        shiftInputView(to: anotherInputView)
        // When:
        shiftInputView(to: nil)
        // Then:
        XCTAssertNil(state.previousInputView, "Clears previous input view state.")
        XCTAssertEqual(state.currentInputView, anInputView, "Updates current input view state.")
        XCTAssertEqual(delegate.previousFocusedInputView, anotherInputView, "Allows delegate to blur previous input view.")

        // Given:
        shiftInputView(to: anInputView)
        shiftInputView(to: anotherInputView)
        // When:
        delegate.shouldRefocus = false
        shiftInputView(to: nil)
        // Then:
        XCTAssertEqual(state.previousInputView, anotherInputView, "Clears previous input view state.")
        XCTAssertNil(state.currentInputView, "Unsets current input view state, without refocus.")
        XCTAssertEqual(delegate.previousFocusedInputView, anotherInputView, "Still allows delegate to blur previous input view.")
    }

    func testDismissalWithWaitingSegue() {
        // Test guarding:
        XCTAssertFalse(state.setupWaitingSegue(for: TestFormFocusStateDelegate.dismissalSegueIdentifier),
            "Needs to have current input view state.")
        shiftInputView(to: anInputView)
        state.shouldGuardSegues = false
        XCTAssertFalse(state.setupWaitingSegue(for: TestFormFocusStateDelegate.dismissalSegueIdentifier),
            "Needs to be enabled.")
        state.shouldGuardSegues = true
        XCTAssertFalse(state.setupWaitingSegue(for: "Some-Segue"),
            "Needs to be a dismissal segue identifier, per delegate.")
        // Given the above setup. Test.
        delegate.waitingSegueExpectation = expectation(description: "Segue will complete.")
        XCTAssertTrue(state.setupWaitingSegue(for: TestFormFocusStateDelegate.dismissalSegueIdentifier))
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNil(state.currentInputView, "Unsets current input view state.")
    }

}
