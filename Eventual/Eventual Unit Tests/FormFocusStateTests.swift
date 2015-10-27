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

        override init() {
            super.init()
        }
        func focusInputView(view: UIView) -> Bool {
            self.focusedInputView = view
            return true
        }
        func blurInputView(view: UIView, withNextView nextView: UIView?) -> Bool {
            self.previousFocusedInputView = view
            self.focusedInputView = nil
            return true
        }
        func isDismissalSegue(identifier: String) -> Bool {
            return identifier == "Dismissal-Segue"
        }
        func performWaitingSegue(completionHandler: () -> Void) {
            completionHandler()
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
        self.state.isShiftingCurrentInputView = false
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
    }

    func testSetupWaitingSegueForIdentifier() {
    }

    func testPerformWaitingSegue() {
    }

}
