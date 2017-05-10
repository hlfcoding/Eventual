//
//  FormFocusState.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol FormFocusStateDelegate: NSObjectProtocol {

    func shouldRefocus(to view: UIView, from currentView: UIView?) -> Bool
    func transitionFocus(to view: UIView?, from currentView: UIView?, completion: (() -> Void)?)

    func isDismissalSegue(_ identifier: String) -> Bool
    func performWaitingSegue(_ identifier: String, completion: @escaping () -> Void)
    func shouldDismissalSegueWait(for inputView: UIView) -> Bool

}

class FormFocusState {

    weak var delegate: FormFocusStateDelegate!

    var currentInputView: UIView? {
        didSet {
            // (breakpoint)
        }
    }
    var previousInputView: UIView? {
        didSet {
            // (breakpoint)
        }
    }
    var isShiftingToInputView = false

    var shouldGuardSegues = true
    fileprivate var isWaitingForDismissal = false
    private var waitingSegueIdentifier: String?

    init(delegate: FormFocusStateDelegate) {
        self.delegate = delegate
    }

    func shiftInputView(to view: UIView?, completion: (() -> Void)? = nil) {
        guard view !== currentInputView && !isShiftingToInputView else {
            if isShiftingToInputView {
                assertionFailure("Extra shiftToInputView call for interaction.")
            }
            return
        }
        isShiftingToInputView = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isShiftingToInputView = false
        }

        let isRefocusing =
            view == nil && previousInputView != nil && !isWaitingForDismissal &&
            delegate.shouldRefocus(to: previousInputView!, from: currentInputView)
        let nextView = isRefocusing ? previousInputView : view

        delegate.transitionFocus(to: nextView, from: currentInputView) { finished in
            self.previousInputView = isRefocusing ? nil : self.currentInputView
            self.currentInputView = nextView
            completion?()

            if self.isWaitingForDismissal {
                self.performWaitingSegue()
            }
        }
    }

    func setupWaitingSegue(for identifier: String) -> Bool {
        guard shouldGuardSegues && delegate.isDismissalSegue(identifier),
            let currentInputView = currentInputView,
            delegate.shouldDismissalSegueWait(for: currentInputView)
            else { return false }

        isWaitingForDismissal = true
        waitingSegueIdentifier = identifier
        previousInputView = nil
        shiftInputView(to: nil)
        return true
    }

    private func performWaitingSegue() {
        guard let identifier = waitingSegueIdentifier else { return }
        isWaitingForDismissal = false
        delegate.performWaitingSegue(identifier) {
            self.waitingSegueIdentifier = nil
        }
    }

}

extension FormFocusState: CustomDebugStringConvertible {

    var debugDescription: String {
        return String.debugDescriptionForGroup(label: "FormFocusState", attributes: [
            "currentInputView": currentInputView?.description,
            "previousInputView": previousInputView?.description,
            "isShiftingToInputView": isShiftingToInputView.description,
            "isWaitingForDismissal": isWaitingForDismissal.description,
        ])
    }

}
