//
//  FormFocusState.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol FormFocusStateDelegate: NSObjectProtocol {

    var isDebuggingInputState: Bool { get set }

    func focusInputView(view: UIView, completionHandler: ((FormError?) -> Void)?)
    func blurInputView(view: UIView, withNextView nextView: UIView?, completionHandler: ((FormError?) -> Void)?)
    func shouldRefocusInputView(view: UIView, fromView currentView: UIView?) -> Bool

    func isDismissalSegue(identifier: String) -> Bool
    func performWaitingSegueWithIdentifier(identifier: String, completionHandler: () -> Void)
    func shouldDismissalSegueWaitForInputView(view: UIView) -> Bool

}

class FormFocusState {

    weak var delegate: FormFocusStateDelegate!

    var currentInputView: UIView? {
        didSet {
            if delegate.isDebuggingInputState {
                guard let inputName = currentInputView?.accessibilityLabel else { return }
                print("Updated currentInputView to \(inputName)")
            }
        }
    }
    var previousInputView: UIView? {
        didSet {
            if delegate.isDebuggingInputState {
                guard let inputName = previousInputView?.accessibilityLabel else { return }
                print("Updated previousInputView to \(inputName)")
            }
        }
    }
    var isShiftingToInputView = false

    var shouldGuardSegues = true
    private var isWaitingForDismissal = false
    private var waitingSegueIdentifier: String?

    init(delegate: FormFocusStateDelegate) {
        self.delegate = delegate
    }

    func shiftToInputView(view: UIView?, completionHandler: ((FormError?) -> Void)? = nil) {
        guard view !== currentInputView && !isShiftingToInputView else {
            if isShiftingToInputView {
                assertionFailure("Extra shiftToInputView call for interaction.")
            }
            return
        }
        isShiftingToInputView = true
        dispatchAfter(0.1) { self.isShiftingToInputView = false }

        let isRefocusing =
            view == nil && previousInputView != nil && !isWaitingForDismissal &&
            delegate.shouldRefocusInputView(previousInputView!, fromView: currentInputView)
        let nextView = isRefocusing ? previousInputView : view

        let completeShiftInputView = {
            self.previousInputView = isRefocusing ? nil : self.currentInputView

            self.currentInputView = nextView

            if let currentInputView = self.currentInputView {
                self.delegate.focusInputView(currentInputView, completionHandler: completionHandler)
            }

            if self.isWaitingForDismissal {
                self.performWaitingSegue()
            }
        }

        if let currentInputView = self.currentInputView {
            delegate.blurInputView(currentInputView, withNextView: nextView) { error in
                guard error == nil else {
                    completionHandler?(error)
                    return
                }
                completeShiftInputView()
            }
        } else {
            completeShiftInputView()
        }
    }

    func setupWaitingSegueForIdentifier(identifier: String) -> Bool {
        guard shouldGuardSegues && delegate.isDismissalSegue(identifier),
            let currentInputView = currentInputView
            where delegate.shouldDismissalSegueWaitForInputView(currentInputView)
            else { return false }

        isWaitingForDismissal = true
        waitingSegueIdentifier = identifier
        previousInputView = nil
        shiftToInputView(nil)
        return true
    }

    private func performWaitingSegue() {
        guard let identifier = waitingSegueIdentifier else { return }
        isWaitingForDismissal = false
        delegate.performWaitingSegueWithIdentifier(identifier) {
            self.waitingSegueIdentifier = nil
        }
    }

}

extension FormFocusState: CustomDebugStringConvertible {

    var debugDescription: String {
        return String.debugDescriptionForGroupWithLabel("FormFocusState", attributes: [
            "currentInputView": currentInputView?.description,
            "previousInputView": previousInputView?.description,
            "isShiftingToInputView": isShiftingToInputView.description,
            "isWaitingForDismissal": isWaitingForDismissal.description,
        ])
    }

}
