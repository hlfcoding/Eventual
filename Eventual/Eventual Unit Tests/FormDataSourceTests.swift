//
//  FormDataSourceTests.swift
//  Eventual
//
//  Created by Peng Wang on 12/19/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

class FormDataSourceTests: XCTestCase {

    class TestFormDataObject: NSObject {
        var identifier = "Some-Identifier"
        var title = "Some Title"
        var details = "Here are some details."
    }

    class TestFormDataSourceDelegate: NSObject, FormDataSourceDelegate {

        var dataObject = TestFormDataObject()
        let titleTextField = UITextField(frame: CGRectZero)
        let detailsTextView = UITextView(frame: CGRectZero)
        var inputViews: [UIView] { return [titleTextField, detailsTextView] }

        var didChangeDataObjectValueCallCount = 0
        var didCommitValueForInputViewCallCount = 0

        var formDataObject: NSObject { return dataObject }
        var formDataValueToInputViewKeyPathsMap: [String: AnyObject] {
            return [
                "title": "titleTextField",
                "details": "detailsTextView"
            ]
        }
        func infoForInputView(view: UIView) -> (name: String, valueKeyPath: String, emptyValue: AnyObject) {
            let name: String!
            let valueKeyPath: String!
            let emptyValue: AnyObject!
            switch view {
            case self.titleTextField:
                name = "Title"
                valueKeyPath = "title"
                emptyValue = ""
            case self.detailsTextView:
                name = "Details"
                valueKeyPath = "details"
                emptyValue = ""

            default: fatalError("Unimplemented form data key.")
            }
            return (name, valueKeyPath, emptyValue)
        }

        func formDidChangeDataObjectValue(value: AnyObject?, atKeyPath keyPath: String) {
            self.didChangeDataObjectValueCallCount += 1
        }
        func formDidCommitValueForInputView(view: UIView) {
            self.didCommitValueForInputViewCallCount += 1
        }

    }

    var dataSource: FormDataSource!
    var delegate: TestFormDataSourceDelegate!

    override func setUp() {
        super.setUp()

        self.delegate = TestFormDataSourceDelegate()
        self.dataSource = FormDataSource(delegate: self.delegate)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertEqual(self.delegate.titleTextField.accessibilityLabel, "Title", "Sets input accessibility label.")
        XCTAssertEqual(self.delegate.detailsTextView.accessibilityLabel, "Details", "Sets input accessibility label.")
    }

    func testManualInitialization() {
        self.dataSource.initializeInputViewsWithFormDataObject()
        XCTAssertEqual(self.delegate.titleTextField.text, self.delegate.dataObject.title)
        XCTAssertEqual(self.delegate.detailsTextView.text, self.delegate.dataObject.details)
    }

    func testChangeFormDataValue() {
        self.dataSource.changeFormDataValue("Changed Title", atKeyPath: "title")
        XCTAssertEqual(self.delegate.dataObject.title, "Changed Title")
        XCTAssertEqual(self.delegate.didChangeDataObjectValueCallCount, 1)
    }

    func testForEachInputView() {
        var callCount = 0
        self.dataSource.forEachInputView() { (inputView) in
            XCTAssertTrue(self.delegate.inputViews.contains(inputView), "Passes input view into block.")
            callCount += 1
        }
        XCTAssertEqual(callCount, self.delegate.inputViews.count, "Calls block for each input view.")
    }

    func testSetValueForInputView() {
        let newTitle = "New Title"
        self.dataSource.setValue(newTitle, forInputView: self.delegate.titleTextField)
        XCTAssertEqual(self.delegate.titleTextField.text, newTitle, "Sets input view value regardless of input type.")
        XCTAssertEqual(self.delegate.didCommitValueForInputViewCallCount, 0, "Can optionally call commit handler.")

        let newDetails = "Here are some new details."
        self.dataSource.setValue(newDetails, forInputView: self.delegate.detailsTextView, commit: true)
        XCTAssertEqual(self.delegate.detailsTextView.text, newDetails, "Sets input view value regardless of input type.")
        XCTAssertEqual(self.delegate.didCommitValueForInputViewCallCount, 1, "Can optionally call commit handler.")
    }

}
