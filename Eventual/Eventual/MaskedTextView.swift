//
//  MaskedTextView.swift
//  Eventual
//
//  Created by Peng Wang on 12/21/15.
//  Copyright © 2015 Eventual App. All rights reserved.
//

import UIKit

class MaskedTextView: UITextView {

    var maskHeight: CGFloat = 20.0
    var maskOpaqueColor: UIColor!
    var topMaskCheckContentOffsetThreshold: CGFloat = 44.0

    // Check in a place like scrollViewDidScroll.
    var shouldHideTopMask: Bool {
        guard self.contentOffset.y <= self.topMaskCheckContentOffsetThreshold else { return false }
        guard self.text.isEmpty || self.contentOffset.y <= fabs(self.scrollIndicatorInsets.top) else { return false }
        return true
    }

    private weak var containerView: UIView!

    // Call in a place like viewDidLoad.
    func setUpTopMask() {
        guard let containerView = self.superview else { fatalError("Requires container view.") }
        self.containerView = containerView
        self.containerView.layer.mask = CAGradientLayer()
        guard let opaqueColor = self.containerView.backgroundColor else { fatalError("Requires container background color.") }
        self.maskOpaqueColor = opaqueColor

        self.toggleTopMask(false)
        self.contentInset = UIEdgeInsets(top: -(self.maskHeight / 2.0), left: 0.0, bottom: 0.0, right: 0.0)
        self.scrollIndicatorInsets = UIEdgeInsets(
            top: self.maskHeight / 2.0, left: 0.0,
            bottom: self.maskHeight / 2.0, right: 0.0
        )
    }

    // Call in a place like scrollViewDidScroll.
    func toggleTopMask(visible: Bool) {
        let opaqueColor: CGColor = self.maskOpaqueColor.CGColor // NOTE: We must explicitly type or we get an error.
        let clearColor: CGColor = UIColor.clearColor().CGColor
        let topColor = !visible ? opaqueColor : clearColor
        guard let maskLayer = self.containerView.layer.mask as? CAGradientLayer else { return }
        maskLayer.colors = [topColor, opaqueColor, opaqueColor, clearColor] as [AnyObject]
    }

    // Call in a place like viewDidLayoutSubviews.
    func updateTopMask() {
        let heightRatio = self.maskHeight / self.containerView.frame.size.height
        guard let maskLayer = self.containerView.layer.mask as? CAGradientLayer else { return }
        maskLayer.locations = [0.0, heightRatio, 1.0 - heightRatio, 1.0]
        maskLayer.frame = self.containerView.bounds
    }

}
