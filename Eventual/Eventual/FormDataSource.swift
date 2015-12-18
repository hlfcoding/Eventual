//
//  FormDataSource.swift
//  Eventual
//
//  Created by Peng Wang on 12/18/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import UIKit

protocol FormDataSourceDelegate: NSObjectProtocol {

    var formDataObject: NSObject { get }

    var formDataValueToInputViewKeyPathsMap: [String: AnyObject] { get }
    func infoForInputView(view: UIView) -> (name: String, valueKeyPath: String, emptyValue: AnyObject)

    func formDidChangeDataObjectValue(value: AnyObject?, atKeyPath keyPath: String)
    func formDidCommitValueForInputView(view: UIView)

}

class FormDataSource {

    weak var delegate: FormDataSourceDelegate!

    init(delegate: FormDataSourceDelegate) {
        self.delegate = delegate
        self.setInputAccessibilityLabels()
    }

    func changeFormDataValue(value: AnyObject?, atKeyPath keyPath: String) {
        self.delegate.formDataObject.setValue(value, forKeyPath: keyPath)
        self.delegate.formDidChangeDataObjectValue(value, atKeyPath: keyPath)
    }

    func forEachInputView(block: (inputView: UIView) -> Void) {
        for (_, viewKeyPath) in self.delegate.formDataValueToInputViewKeyPathsMap {
            if let viewKeyPaths = viewKeyPath as? [String] {
                for viewKeyPath in viewKeyPaths {
                    guard let view = self.viewForKeyPath(viewKeyPath) else { continue }
                    block(inputView: view)
                }
            } else if let viewKeyPath = viewKeyPath as? String,
                          view = self.viewForKeyPath(viewKeyPath)
            {
                block(inputView: view)
            }
        }
    }

    func setInputAccessibilityLabels() {
        self.forEachInputView() {
            let (name, _, _) = self.delegate.infoForInputView($0)
            $0.accessibilityLabel = name
        }
    }

    func initializeInputViewsWithFormDataObject() {
        for valueKeyPath in self.delegate.formDataValueToInputViewKeyPathsMap.keys {
            self.updateInputViewWithFormDataValue(valueKeyPath, commit: true)
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
        default: fatalError("Unsupported input-view type")
        }

        guard shouldCommit else { return }
        self.delegate.formDidCommitValueForInputView(view)
    }

    func updateFormDataForInputView(view: UIView, validated: Bool = false) {
        let (_, valueKeyPath, emptyValue) = self.delegate.infoForInputView(view)
        var rawValue = self.valueForInputView(view)
        // TODO: KVC validation support.

        var isValid = true
        if validated {
            do {
                try self.delegate.formDataObject.validateValue(&rawValue, forKeyPath: valueKeyPath)
            } catch let error as NSError {
                print("Validation error: \(error)")
                isValid = false
            }
        }
        let newValue = rawValue ?? emptyValue
        if !validated || isValid {
            self.changeFormDataValue(newValue, atKeyPath: valueKeyPath)
        }

        guard validated else { return }
        if let viewKeyPaths = self.delegate.formDataValueToInputViewKeyPathsMap[valueKeyPath] as? [String] {
            // FIXME: This may cause redundant setting.
            for viewKeyPath in viewKeyPaths {
                guard let view = self.viewForKeyPath(viewKeyPath) else { continue }
                self.setValue(newValue, forInputView: view)
            }
        } else {
            self.setValue(newValue, forInputView: view)
        }
    }

    func updateInputViewsWithFormDataObject(customFormDataObject: NSObject? = nil) {
        // FIXME: Implement customFormDataObject support.
        for valueKeyPath in self.delegate.formDataValueToInputViewKeyPathsMap.keys {
            self.updateInputViewWithFormDataValue(valueKeyPath, commit: true)
        }
    }

    func updateInputViewWithFormDataValue(valueKeyPath: String, commit shouldCommit: Bool = false) {
        // Arrays are supported for multiple inputs mapping to same value key-path.
        guard let viewKeyPath: AnyObject = self.delegate.formDataValueToInputViewKeyPathsMap[valueKeyPath] else { return }
        let viewKeyPaths: [String]
        if let array = viewKeyPath as? [String] {
            viewKeyPaths = array
        } else if let string = viewKeyPath as? String {
            viewKeyPaths = [ string ]
        } else {
            fatalError("Unsupported view key-path type.")
        }
        for viewKeyPath in viewKeyPaths {
            guard let value: AnyObject = self.delegate.formDataObject.valueForKeyPath(valueKeyPath),
                      view = self.viewForKeyPath(viewKeyPath)
                  else { continue }
            self.setValue(value, forInputView: view, commit: shouldCommit)
        }
    }

    func valueForInputView(view: UIView) -> AnyObject? {
        switch view {
        case let textField as UITextField: return textField.text?.copy()
        case let textView as UITextView: return textView.text?.copy()
        case let datePicker as UIDatePicker: return datePicker.date.copy()
        default: fatalError("Unsupported input-view type")
        }
    }

    private func viewForKeyPath(keyPath: String) -> UIView? {
        return (self.delegate as! NSObject).valueForKeyPath(keyPath) as? UIView
    }
    
}
