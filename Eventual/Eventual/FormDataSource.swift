//
//  FormDataSource.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol FormDataSourceDelegate: NSObjectProtocol {

    var formDataObject: NSObject { get }

    var formDataValueToInputView: KeyPathsMap { get }
    func infoForInputView(view: UIView) -> (name: String, valueKeyPath: String, emptyValue: AnyObject)

    func formDidChangeDataObjectValue(value: AnyObject?, atKeyPath keyPath: String)
    func formDidCommitValueForInputView(view: UIView)

}

class FormDataSource {

    weak var delegate: FormDataSourceDelegate!

    init(delegate: FormDataSourceDelegate) {
        self.delegate = delegate
        setInputAccessibilityLabels()
    }

    func changeFormDataValue(value: AnyObject?, atKeyPath keyPath: String) {
        delegate.formDataObject.setValue(value, forKeyPath: keyPath)
        delegate.formDidChangeDataObjectValue(value, atKeyPath: keyPath)
    }

    func forEachInputView(block: (inputView: UIView, valueKeyPath: String) -> Void) {
        for valueKeyPath in delegate.formDataValueToInputView.keys {
            forEachInputViewForValueKeyPath(valueKeyPath, block: block)
        }
    }

    private func forEachInputViewForValueKeyPath(keyPath: String, block: (inputView: UIView, valueKeyPath: String) -> Void) {
        guard let viewKeyPath: AnyObject = delegate.formDataValueToInputView[keyPath] else { return }
        let viewKeyPaths: [String]
        if let array = viewKeyPath as? [String] {
            viewKeyPaths = array
        } else if let string = viewKeyPath as? String {
            viewKeyPaths = [ string ]
        } else {
            preconditionFailure("Unsupported view key-path type.")
        }
        for viewKeyPath in viewKeyPaths {
            guard let view = viewForKeyPath(viewKeyPath) else { continue }
            block(inputView: view, valueKeyPath: keyPath)
        }
    }

    func setInputAccessibilityLabels() {
        forEachInputView { (inputView, _) in
            let (name, _, _) = self.delegate.infoForInputView(inputView)
            inputView.accessibilityLabel = name
        }
    }

    func initializeInputViewsWithFormDataObject() {
        forEachInputView {
            guard let value: AnyObject = self.delegate.formDataObject.valueForKeyPath($1) else { return }
            self.setValue(value, forInputView: $0, commit: true)
        }
    }

    func setValue(value: AnyObject, forInputView view: UIView, commit shouldCommit: Bool = false) {
        switch view {
        case let textField as UITextField:
            guard let text = value as? String where text != textField.text else { return }
            textField.text = text
        case let textView as UITextView:
            guard let text = value as? String where text != textView.text else { return }
            textView.text = text
        case let datePicker as UIDatePicker:
            guard let date = value as? NSDate where date != datePicker.date else { return }
            datePicker.date = date
        default: fatalError("Unsupported input-view type.")
        }

        guard shouldCommit else { return }
        delegate.formDidCommitValueForInputView(view)
    }

    func updateFormDataForInputView(view: UIView, validated: Bool = false, updateDataObject: Bool = true) {
        let (_, valueKeyPath, emptyValue) = delegate.infoForInputView(view)
        var rawValue = valueForInputView(view)
        // TODO: KVC validation support.

        var isValid = true
        if validated {
            do {
                try delegate.formDataObject.validateValue(&rawValue, forKeyPath: valueKeyPath)
            } catch let error as NSError {
                print("Validation error: \(error)")
                isValid = false
            }
        }
        let newValue = rawValue ?? emptyValue
        if !validated || isValid {
            changeFormDataValue(newValue, atKeyPath: valueKeyPath)
        }

        guard updateDataObject else { return }
        // FIXME: This may cause redundant setting.
        forEachInputViewForValueKeyPath(valueKeyPath) { (inputView, valueKeyPath) in
            self.setValue(newValue, forInputView: inputView)
        }
    }

    func valueForInputView(view: UIView) -> AnyObject? {
        switch view {
        case let textField as UITextField: return textField.text?.copy()
        case let textView as UITextView: return textView.text?.copy()
        case let datePicker as UIDatePicker: return datePicker.date.copy()
        default: fatalError("Unsupported input-view type.")
        }
    }

    private func viewForKeyPath(keyPath: String) -> UIView? {
        return (delegate as! NSObject).valueForKeyPath(keyPath) as? UIView
    }

}
