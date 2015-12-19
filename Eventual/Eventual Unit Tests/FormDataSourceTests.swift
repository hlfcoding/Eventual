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
    }

    class TestFormDataSourceDelegate: NSObject, FormDataSourceDelegate {

        var dataObject = TestFormDataObject()
        let titleTextField = UITextField(frame: CGRectZero)
        var inputViews: [UIView] { return [titleTextField] }

        var didChangeDataObjectValueCallCount = 0
        var didCommitValueForInputViewCallCount = 0

        var formDataObject: NSObject { return dataObject }
        var formDataValueToInputViewKeyPathsMap: [String: AnyObject] {
            return [
                "title": "titleTextField"
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
        XCTAssertEqual(self.delegate.titleTextField.accessibilityLabel, "Title", "Sets input accessibility labels.")
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

}
