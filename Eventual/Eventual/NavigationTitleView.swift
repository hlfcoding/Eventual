//
//  NavigationTitleView.swift
//  Eventual
//
//  Created by Peng Wang on 7/20/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETNavigationTitleView) protocol NavigationTitleViewProtocol: NSObjectProtocol {
    
    var textColor: UIColor? { get set }
    
}

@objc(ETNavigationTitleView) class NavigationTitleView: UIView {
    
    var text: String!
    
    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var interstitialLabel: UILabel!
    @IBOutlet private weak var mainConstraint: NSLayoutConstraint!
    @IBOutlet private weak var interstitialConstraint: NSLayoutConstraint!
    
    init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        self.setUp()
    }
    
    private func setUp() {
        self.clipsToBounds = true
        self.isAccessibilityElement = true
        self.accessibilityLabel = NSLocalizedString(ETLabel.MonthScreenTitle.toRaw(), comment: "")
        self.text = self.mainLabel.text
    }
    
    override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
    // MARK: Public
    
    func setText(text: String, animated: Bool) -> Bool {
        if text == self.text { return false }
        self.text = text
        if !animated {
            self.mainLabel.text = text
            return true
        }
        self.interstitialLabel.text = text
        let savedMainConstant = self.mainConstraint.constant
        let savedInterstitialConstant = self.interstitialConstraint.constant
        self.mainConstraint.constant = -self.mainLabel.frame.size.height
        self.interstitialConstraint.constant = 0.0
        self.setNeedsUpdateConstraints()
        // TODO: Using spring animation.
        UIView.animateWithDuration( 0.3,
            animations: { () in self.layoutIfNeeded() },
            completion: { (finished: Bool) in
                self.mainLabel.text = self.interstitialLabel.text;
                self.mainConstraint.constant = savedMainConstant
                self.interstitialConstraint.constant = savedInterstitialConstant
            }
        )
        return true
    }
}

extension NavigationTitleView: NavigationTitleViewProtocol {
    
    var textColor: UIColor? {
    get {
        return self.textColor
    }
    set {
        if textColor == newValue { return }
        self.textColor = newValue
        self.mainLabel.textColor = self.textColor
        self.interstitialLabel.textColor = self.textColor
    }
    }
    
}