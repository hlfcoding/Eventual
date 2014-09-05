//
//  NavigationTitleView.swift
//  Eventual
//
//  Created by Peng Wang on 7/20/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETNavigationTitleView) class NavigationTitleView: UIView {

    var text: String!

    // MARK: - NavigationTitleViewProtocol
    
    var textColor: UIColor! {
        didSet {
            if self.textColor == oldValue { return }
            self.mainLabel.textColor = self.textColor
            self.interstitialLabel.textColor = self.textColor
        }
    }

    // MARK: Private
    
    @IBOutlet private var mainLabel: UILabel!
    @IBOutlet private var interstitialLabel: UILabel!
    @IBOutlet private var mainConstraint: NSLayoutConstraint!
    @IBOutlet private var interstitialConstraint: NSLayoutConstraint!

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }
    
    private func setUp() {
        self.clipsToBounds = true
        self.isAccessibilityElement = true
        self.accessibilityLabel = NSLocalizedString(ETLabel.MonthScreenTitle.toRaw(), comment: "")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.completeSetup()
    }
    
    private func completeSetup() {
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
        UIView.animateWithDuration( 0.4, delay: 0.0,
            usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0,
            options: .BeginFromCurrentState,
            animations: { self.layoutIfNeeded() },
            completion: { finished in
                self.mainLabel.text = self.interstitialLabel.text;
                self.mainConstraint.constant = savedMainConstant
                self.interstitialConstraint.constant = savedInterstitialConstant
            }
        )
        return true
    }
}