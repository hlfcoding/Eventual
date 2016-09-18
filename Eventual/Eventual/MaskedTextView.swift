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

    /** Call in a place like viewDidAppear. */
    func setUpTopMask() {
        guard let superview = superview else { preconditionFailure("Requires container view.") }
        containerView = superview
        containerView.layer.mask = CAGradientLayer()

        if maskOpaqueColor == nil {
            guard let opaqueColor = containerView.backgroundColor else { preconditionFailure("Requires container background color.") }
            maskOpaqueColor = opaqueColor
        }

        toggleTopMask(visible: false)
        scrollIndicatorInsets = UIEdgeInsets(top: maskHeight / 2, left: 0, bottom: maskHeight / 2, right: 0)
    }

    /** Call in a place like scrollViewDidScroll. */
    func toggleTopMask(visible: Bool) {
        guard let maskLayer = containerView.layer.mask as? CAGradientLayer else { return }
        completeSetUpTopMask()

        maskLayer.colors = {
            let opaqueColor: CGColor = maskOpaqueColor.cgColor // NOTE: We must explicitly type or we get an error.
            let clearColor: CGColor = UIColor.clear.cgColor
            let topColor = !visible ? opaqueColor : clearColor
            return [topColor, opaqueColor, opaqueColor, clearColor]
            }() as [AnyObject]
    }

    private func completeSetUpTopMask() {
        guard let maskLayer = containerView.layer.mask as? CAGradientLayer,
            maskLayer.locations == nil && maskLayer.frame == .zero
            else { return }

        maskLayer.locations = {
            let heightRatio = Float(maskHeight / containerView.frame.height)
            return [0, NSNumber(value: heightRatio), NSNumber(value: 1 - heightRatio), 1]
        }()
        maskLayer.frame = containerView.bounds
    }

}
