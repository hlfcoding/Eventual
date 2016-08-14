//
//  MaskedTextView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class MaskedTextView: UITextView {

    @IBInspectable var maskHeight: CGFloat = 20
    @IBInspectable var maskOpaqueColor: UIColor!
    @IBInspectable var topMaskCheckContentOffsetThreshold: CGFloat = 44

    /** Check in a place like scrollViewDidScroll. */
    var shouldHideTopMask: Bool {
        guard contentOffset.y <= topMaskCheckContentOffsetThreshold else { return false }
        guard text.isEmpty || contentOffset.y <= fabs(scrollIndicatorInsets.top) else { return false }
        return true
    }

    private weak var containerView: UIView!

    /** Call in a place like viewDidLoad. */
    func setUpTopMask() {
        guard let superview = superview else { preconditionFailure("Requires container view.") }
        containerView = superview
        containerView.layer.mask = CAGradientLayer()

        if maskOpaqueColor == nil {
            guard let opaqueColor = containerView.backgroundColor else { preconditionFailure("Requires container background color.") }
            maskOpaqueColor = opaqueColor
        }

        toggleTopMask(false)
        contentInset = UIEdgeInsets(top: -(maskHeight / 2), left: 0, bottom: 0, right: 0)
        scrollIndicatorInsets = UIEdgeInsets(top: maskHeight / 2, left: 0, bottom: maskHeight / 2, right: 0)
    }

    /** Call in a place like scrollViewDidScroll. */
    func toggleTopMask(visible: Bool) {
        guard let maskLayer = containerView.layer.mask as? CAGradientLayer else { return }

        maskLayer.colors = {
            let opaqueColor: CGColor = maskOpaqueColor.CGColor // NOTE: We must explicitly type or we get an error.
            let clearColor: CGColor = UIColor.clearColor().CGColor
            let topColor = !visible ? opaqueColor : clearColor
            return [topColor, opaqueColor, opaqueColor, clearColor]
            }() as [AnyObject]
    }

    // Call in a place like viewDidLayoutSubviews.
    func updateTopMask() {
        guard let maskLayer = containerView.layer.mask as? CAGradientLayer else { return }

        maskLayer.locations = {
            let heightRatio = maskHeight / containerView.frame.height
            return [0, heightRatio, 1 - heightRatio, 1]
        }()
        maskLayer.frame = containerView.bounds
    }

}
