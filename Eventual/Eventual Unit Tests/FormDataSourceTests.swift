//
//  FormDataSourceTests.swift
//  Eventual Unit Tests
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import XCTest
@testable import Eventual

final class FormDataSourceTests: XCTestCase {

    final class TestFormDataObject: NSObject {
        var identifier = "Some-Identifier"
        var title = "Some Title"
        var details = "Here are some details."
        var name = "John Doe"
    }

    final class TestFormDataSourceDelegate: NSObject, FormDataSourceDelegate {

        var dataObject = TestFormDataObject()
        let titleField = UITextField(frame: .zero)
        let detailsField = UITextView(frame: .zero)
        // Assumes these fields know how to show only their part of the name.
        let firstNameField = UITextField(frame: .zero)
        let lastNameField = UITextField(frame: .zero)
        var inputViews: [UIView] { return [titleField, detailsField, firstNameField, lastNameField] }

        var didChangeDataObjectValueCallCount = 0
        var didCommitValueForInputViewCallCount = 0

        var formDataObject: NSObject { return dataObject }
        var formDataValueToInputView: KeyPathsMap {
            return [
                #keyPath(TestFormDataObject.title): #keyPath(titleField),
                #keyPath(TestFormDataObject.details): #keyPath(detailsField),
                #keyPath(TestFormDataObject.name): [ #keyPath(firstNameField), #keyPath(lastNameField) ],
            ]
        }

        func formInfo(for inputView: UIView) -> (name: String, valueKeyPath: String, emptyValue: Any) {
            let info: (String, String, Any)!
            switch inputView {
            case titleField: info = (name: "Title", valueKeyPath: #keyPath(TestFormDataObject.title), emptyValue: "")
            case detailsField: info = (name: "Details", valueKeyPath: #keyPath(TestFormDataObject.details), emptyValue: "")
            case firstNameField, lastNameField:
                let name: String!
                switch inputView {
                case firstNameField: name = "First Name"
                case lastNameField: name = "Last Name"
                default: fatalError("Unknown field.")
                }
                info = (name: name, valueKeyPath: #keyPath(TestFormDataObject.name), emptyValue: "")
            default: fatalError("Unknown field.")
            }
            return info
        }

        func formDidChangeDataObject<T>(value: T?, for keyPath: String) {
            didChangeDataObjectValueCallCount += 1
        }

        func formDidCommitValue(for inputView: UIView) {
            didCommitValueForInputViewCallCount += 1
        }

    }

    var dataSource: FormDataSource!
    var delegate: TestFormDataSourceDelegate!

    override func setUp() {
        super.setUp()
        delegate = TestFormDataSourceDelegate()
        dataSource = FormDataSource(delegate: delegate)
    }

    func testInitialization() {
        XCTAssertEqual(delegate.titleField.accessibilityLabel, "Title", "Sets input accessibility label.")
        XCTAssertEqual(delegate.detailsField.accessibilityLabel, "Details", "Sets input accessibility label.")
        XCTAssertEqual(delegate.firstNameField.accessibilityLabel, "First Name", "Sets for grouped views.")
        XCTAssertEqual(delegate.lastNameField.accessibilityLabel, "Last Name", "Sets for grouped views.")
    }

    func testManualInitialization() {
        dataSource.initializeInputViewsWithFormDataObject()
        XCTAssertEqual(delegate.titleField.text, delegate.dataObject.title)
        XCTAssertEqual(delegate.detailsField.text, delegate.dataObject.details)
        XCTAssertEqual(delegate.firstNameField.text, delegate.dataObject.name, "Sets for grouped views.")
        XCTAssertEqual(delegate.lastNameField.text, delegate.dataObject.name, "Sets for grouped views.")
    }

    func testChangeFormDataValue() {
        dataSource.changeFormData(value: "Changed Title", for: #keyPath(TestFormDataObject.title))
        XCTAssertEqual(delegate.dataObject.title, "Changed Title")
        XCTAssertEqual(delegate.didChangeDataObjectValueCallCount, 1)
    }

    func testForEachInputView() {
        var callCount = 0
        dataSource.forEachInputView { inputView, _ in
            XCTAssertTrue(self.delegate.inputViews.contains(inputView), "Passes input view into block.")
            callCount += 1
        }
        XCTAssertEqual(callCount, delegate.inputViews.count, "Calls block for each input view (including grouped).")
    }

    func testSetValueForInputView() {
        let newTitle = "New Title"
        dataSource.setValue(newTitle, for: delegate.titleField)
        XCTAssertEqual(delegate.titleField.text, newTitle, "Sets input view value regardless of input type.")
        XCTAssertEqual(delegate.didCommitValueForInputViewCallCount, 0, "Can optionally call commit handler.")

        let newDetails = "Here are some new details."
        dataSource.setValue(newDetails, for: delegate.detailsField, commit: true)
        XCTAssertEqual(delegate.detailsField.text, newDetails, "Sets input view value regardless of input type.")
        XCTAssertEqual(delegate.didCommitValueForInputViewCallCount, 1, "Can optionally call commit handler.")
    }

    func testValueForInputView() {
        dataSource.initializeInputViewsWithFormDataObject()
        guard let title = dataSource.value(for: delegate.titleField) as? String,
            let details = dataSource.value(for: delegate.detailsField) as? String
            else { return XCTFail("Values should be present.") }
        XCTAssertEqual(title, delegate.dataObject.title)
        XCTAssertEqual(details, delegate.dataObject.details)
    }

}
