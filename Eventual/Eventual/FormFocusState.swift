//
//  FormFocusState.swift
//  Eventual
//
//  Created by Peng Wang on 12/18/15.
//  Copyright © 2015 Eventual App. All rights reserved.
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
            if self.delegate.isDebuggingInputState {
                guard let inputName = self.currentInputView?.accessibilityLabel else { return }
                print("Updated currentInputView to \(inputName)")
            }
        }
    }
    var previousInputView: UIView? {
        didSet {
            if self.delegate.isDebuggingInputState {
                guard let inputName = self.previousInputView?.accessibilityLabel else { return }
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
        guard view !== self.currentInputView && !self.isShiftingToInputView else {
            if self.isShiftingToInputView {
                print("Warning: extra shiftToInputView call for interaction.")
            }
            return
        }
        self.isShiftingToInputView = true
        dispatch_after(0.1) { self.isShiftingToInputView = false }

        let isRefocusing = (
            view == nil && self.previousInputView != nil && !self.isWaitingForDismissal &&
            self.delegate.shouldRefocusInputView(self.previousInputView!, fromView: self.currentInputView)
        )
        let nextView = isRefocusing ? self.previousInputView : view

        let completeShiftInputView: () -> Void = {
            self.previousInputView = isRefocusing ? nil : self.currentInputView

            self.currentInputView = nextView

            if let currentInputView = self.currentInputView {
                self.delegate.focusInputView(currentInputView, completionHandler: completionHandler)
            }

            if self.isWaitingForDismissal { self.performWaitingSegue() }
        }

        if let currentInputView = self.currentInputView {
            self.delegate.blurInputView(currentInputView, withNextView: nextView) { (error) in
                guard error == nil else { completionHandler?(error); return }
                completeShiftInputView()
            }
        } else {
            completeShiftInputView()
        }
    }

    func setupWaitingSegueForIdentifier(identifier: String) -> Bool {
        guard self.shouldGuardSegues && self.delegate.isDismissalSegue(identifier),
              let currentInputView = self.currentInputView
              where self.delegate.shouldDismissalSegueWaitForInputView(currentInputView)
              else { return false }
        self.isWaitingForDismissal = true
        self.waitingSegueIdentifier = identifier
        self.previousInputView = nil
        self.shiftToInputView(nil)
        return true
    }

    private func performWaitingSegue() {
        guard let identifier = self.waitingSegueIdentifier else { return }
        self.isWaitingForDismissal = false
        self.delegate.performWaitingSegueWithIdentifier(identifier) {
            self.waitingSegueIdentifier = nil
        }
    }

}

extension FormFocusState: CustomDebugStringConvertible {

    var debugDescription: String {
        return String.debugDescriptionForGroupWithLabel("FormFocusState", attributes: [
            "currentInputView": self.currentInputView?.description,
            "previousInputView": self.previousInputView?.description,
            "isShiftingToInputView": self.isShiftingToInputView.description,
            "isWaitingForDismissal": self.isWaitingForDismissal.description
        ])
    }

}
