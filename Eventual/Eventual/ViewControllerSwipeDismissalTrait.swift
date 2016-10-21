//
//  ViewControllerSwipeDismissalTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class ViewControllerSwipeDismissalTrait {

    var dismissal: (() -> Void)!

    init(viewController: UIViewController, dismissal: @escaping () -> Void) {
        guard viewController.isViewLoaded else { preconditionFailure() }
        let recognizer = UIScreenEdgePanGestureRecognizer(
            target: self, action: #selector(handlePan(sender:))
        ) // ಠ_ಠ Xcode!
        recognizer.edges = .left
        viewController.view.addGestureRecognizer(recognizer)

        self.dismissal = dismissal
    }

    @objc private func handlePan(sender: UIPanGestureRecognizer) {
        guard sender.state == .ended else { return }
        dismissal()
    }

}
