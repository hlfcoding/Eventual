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

        override init() {
            super.init()
        }
        func focusInputView(view: UIView) -> Bool {
            self.focusedInputView = view
            return true
        }
        func blurInputView(view: UIView, withNextView nextView: UIView?) -> Bool {
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
    var delegate: FormFocusStateDelegate!

    override func setUp() {
        super.setUp()

        self.delegate = TestFormFocusStateDelegate()
        self.state = FormFocusState(delegate: self.delegate)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertNil(self.state.currentInputView)
        XCTAssertNil(self.state.previousInputView)
    }

    func testShiftToInputView() {
    }

    func testRefocusPreviousInputView() {
    }

    func testSetupWaitingSegueForIdentifier() {
    }

    func testPerformWaitingSegue() {
    }

}
