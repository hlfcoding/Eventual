//
//  FormDataSourceTests.swift
//  Eventual
//
//  Created by Peng Wang on 12/19/15.
//  Copyright (c) 2015-2016 Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

class FormDataSourceTests: XCTestCase {

    class TestFormDataObject: NSObject {
        var identifier = "Some-Identifier"
        var title = "Some Title"
        var details = "Here are some details."
        var name = "John Doe"
    }

    class TestFormDataSourceDelegate: NSObject, FormDataSourceDelegate {

        var dataObject = TestFormDataObject()
        let titleField = UITextField(frame: CGRectZero)
        let detailsField = UITextView(frame: CGRectZero)
        // Assumes these fields know how to show only their part of the name.
        let firstNameField = UITextField(frame: CGRectZero)
        let lastNameField = UITextField(frame: CGRectZero)
        var inputViews: [UIView] { return [titleField, detailsField, firstNameField, lastNameField] }

        var didChangeDataObjectValueCallCount = 0
        var didCommitValueForInputViewCallCount = 0

        var formDataObject: NSObject { return dataObject }
        var formDataValueToInputViewKeyPathsMap: [String: AnyObject] {
            return [
                "title": "titleField",
                "details": "detailsField",
                "name": [ "firstNameField", "lastNameField" ]
            ]
        }
        func infoForInputView(view: UIView) -> (name: String, valueKeyPath: String, emptyValue: AnyObject) {
            let name: String!, valueKeyPath: String!, emptyValue: AnyObject!
            switch view {
            case self.titleField:
                name = "Title"
                valueKeyPath = "title"
                emptyValue = ""
            case self.detailsField:
                name = "Details"
                valueKeyPath = "details"
                emptyValue = ""
            case self.firstNameField, self.lastNameField:
                switch view {
                case self.firstNameField: name = "First Name"
                case self.lastNameField: name = "Last Name"
                default: fatalError("Unknown field.")
                }
                valueKeyPath = "name"
                emptyValue = ""
            default: fatalError("Unknown field.")
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
        XCTAssertEqual(self.delegate.titleField.accessibilityLabel, "Title", "Sets input accessibility label.")
        XCTAssertEqual(self.delegate.detailsField.accessibilityLabel, "Details", "Sets input accessibility label.")
        XCTAssertEqual(self.delegate.firstNameField.accessibilityLabel, "First Name", "Sets for grouped views.")
        XCTAssertEqual(self.delegate.lastNameField.accessibilityLabel, "Last Name", "Sets for grouped views.")
    }

    func testManualInitialization() {
        self.dataSource.initializeInputViewsWithFormDataObject()
        XCTAssertEqual(self.delegate.titleField.text, self.delegate.dataObject.title)
        XCTAssertEqual(self.delegate.detailsField.text, self.delegate.dataObject.details)
        XCTAssertEqual(self.delegate.firstNameField.text, self.delegate.dataObject.name, "Sets for grouped views.")
        XCTAssertEqual(self.delegate.lastNameField.text, self.delegate.dataObject.name, "Sets for grouped views.")
    }

    func testChangeFormDataValue() {
        self.dataSource.changeFormDataValue("Changed Title", atKeyPath: "title")
        XCTAssertEqual(self.delegate.dataObject.title, "Changed Title")
        XCTAssertEqual(self.delegate.didChangeDataObjectValueCallCount, 1)
    }

    func testForEachInputView() {
        var callCount = 0
        self.dataSource.forEachInputView() { (inputView, valueKeyPath) in
            XCTAssertTrue(self.delegate.inputViews.contains(inputView), "Passes input view into block.")
            callCount += 1
        }
        XCTAssertEqual(callCount, self.delegate.inputViews.count, "Calls block for each input view (including grouped).")
    }

    func testSetValueForInputView() {
        let newTitle = "New Title"
        self.dataSource.setValue(newTitle, forInputView: self.delegate.titleField)
        XCTAssertEqual(self.delegate.titleField.text, newTitle, "Sets input view value regardless of input type.")
        XCTAssertEqual(self.delegate.didCommitValueForInputViewCallCount, 0, "Can optionally call commit handler.")

        let newDetails = "Here are some new details."
        self.dataSource.setValue(newDetails, forInputView: self.delegate.detailsField, commit: true)
        XCTAssertEqual(self.delegate.detailsField.text, newDetails, "Sets input view value regardless of input type.")
        XCTAssertEqual(self.delegate.didCommitValueForInputViewCallCount, 1, "Can optionally call commit handler.")
    }


    func testValueForInputView() {
        self.dataSource.initializeInputViewsWithFormDataObject()
        XCTAssertEqual((self.dataSource.valueForInputView(self.delegate.titleField) as! String), self.delegate.dataObject.title)
        XCTAssertEqual((self.dataSource.valueForInputView(self.delegate.detailsField) as! String), self.delegate.dataObject.details)
    }
}
