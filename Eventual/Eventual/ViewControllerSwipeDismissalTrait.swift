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
        self.dismissal = dismissal

        let recognizer = UIScreenEdgePanGestureRecognizer(
            target: self, action: #selector(handlePan(sender:))
        )
        recognizer.edges = .left
        viewController.view.addGestureRecognizer(recognizer)
    }

    @objc private func handlePan(sender: UIPanGestureRecognizer) {
        guard sender.state == .ended else { return }
        dismissal()
    }

}
