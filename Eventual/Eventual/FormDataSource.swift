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
    func formInfo(for inputView: UIView) -> (name: String, valueKeyPath: String, emptyValue: Any)

    func formDidChangeDataObject<T>(value: T?, for keyPath: String)
    func formDidCommitValue(for inputView: UIView)

}

class FormDataSource {

    weak var delegate: FormDataSourceDelegate!

    init(delegate: FormDataSourceDelegate) {
        self.delegate = delegate
        setInputAccessibilityLabels()
    }

    func changeFormData<T>(value: T?, for keyPath: String) {
        delegate.formDataObject.setValue(value, forKeyPath: keyPath)
        delegate.formDidChangeDataObject(value: value, for: keyPath)
    }

    func forEachInputView(block: (_ inputView: UIView, _ valueKeyPath: String) -> Void) {
        for valueKeyPath in delegate.formDataValueToInputView.keys {
            forEachInputView(for: valueKeyPath, block: block)
        }
    }

    private func forEachInputView(for valueKeyPath: String,
                                  block: (_ inputView: UIView, _ valueKeyPath: String) -> Void) {
        guard let viewKeyPath: Any = delegate.formDataValueToInputView[valueKeyPath]
            else { return }
        let viewKeyPaths: [String]
        if let array = viewKeyPath as? [String] {
            viewKeyPaths = array
        } else if let string = viewKeyPath as? String {
            viewKeyPaths = [ string ]
        } else {
            preconditionFailure("Unsupported view key-path type.")
        }
        for viewKeyPath in viewKeyPaths {
            guard let view = view(for: viewKeyPath) else { continue }
            block(view, valueKeyPath)
        }
    }

    func setInputAccessibilityLabels() {
        forEachInputView { inputView, _ in
            let (name, _, _) = self.delegate.formInfo(for: inputView)
            inputView.accessibilityLabel = name
        }
    }

    func initializeInputViewsWithFormDataObject() {
        forEachInputView { inputView, valueKeyPath in
            guard let value = self.delegate.formDataObject.value(forKeyPath: valueKeyPath) as Any?
                else { return }
            self.setValue(value, for: inputView, commit: true)
        }
    }

    func setValue(_ value: Any, for inputView: UIView, commit shouldCommit: Bool = false) {
        switch (inputView, value) {
        case (let textField as UITextField, let text as String) where text != textField.text:
            textField.text = text
        case (let textView as UITextView, let text as String) where text != textView.text:
            textView.text = text
        case (let datePicker as UIDatePicker, let date as Date) where date != datePicker.date:
            datePicker.setDate(date, animated: false)
        default: return
        }
        guard shouldCommit else { return }
        delegate.formDidCommitValue(for: inputView)
    }

    func updateFormData(for inputView: UIView,
                        validated: Bool = false, updateDataObject: Bool = true) {
        let (_, valueKeyPath, emptyValue) = delegate.formInfo(for: inputView)
        var rawValue = value(for: inputView) as AnyObject?
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
            changeFormData(value: newValue, for: valueKeyPath)
        }

        guard updateDataObject else { return }
        // FIXME: This may cause redundant setting.
        forEachInputView(for: valueKeyPath) { inputView, valueKeyPath in
            self.setValue(newValue as Any, for: inputView)
        }
    }

    func value(for inputView: UIView) -> Any? {
        switch inputView {
        case let textField as UITextField: return textField.text as Any?
        case let textView as UITextView: return textView.text as Any?
        case let datePicker as UIDatePicker: return datePicker.date as Any?
        default: fatalError("Unsupported input-view type.")
        }
    }

    private func view(for keyPath: String) -> UIView? {
        return (delegate as? NSObject)?.value(forKeyPath: keyPath) as? UIView
    }

}
