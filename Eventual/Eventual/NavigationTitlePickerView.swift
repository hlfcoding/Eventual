//
//  NavigationTitlePickerView.swift
//  Eventual
//
//  Created by Peng Wang on 8/1/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import QuartzCore

enum ETNavigationItemType {
    case Label, Button
}

enum ETScrollOrientation {
    case Horizontal, Vertical
}

// MARK: - Delegate

@objc(ETNavigationTitlePickerViewDelegate) protocol NavigationTitlePickerViewDelegate : NSObjectProtocol {
    
    func navigationTitleView(titleView: NavigationTitlePickerView, didChangeVisibleItem visibleItem: UIView)
    
}

// MARK: - Main

@objc(ETNavigationTitleScrollView) class NavigationTitleScrollView : UIScrollView,
    NavigationTitleViewProtocol, UIScrollViewDelegate
{
    
    var pickerViewDelegate: NavigationTitlePickerViewDelegate?
    
    var textColor: UIColor! {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.updateTextAppearance()
            }
        }
    }

    var items: [UIView] { return self.subviews as [UIView] }

    var visibleItem: UIView? {
        didSet {
            if self.visibleItem == oldValue { return }
            if let visibleItem = self.visibleItem {
                if self.pagingEnabled {
                    self.setContentOffset(
                        CGPoint(x: visibleItem.frame.origin.x, y: self.contentOffset.y),
                        animated: true
                    )
                }
            }
            if let delegate = self.pickerViewDelegate {
                delegate.navigationTitleView(
                    (self.superview! as NavigationTitlePickerView),
                    didChangeVisibleItem: self.visibleItem!
                )
            }
        }
    }
    
    var scrollOrientation: ETScrollOrientation = .Vertical

    override var pagingEnabled: Bool {
        didSet {
            self.scrollEnabled = self.pagingEnabled
            self.clipsToBounds = !self.pagingEnabled
            self.scrollOrientation = self.pagingEnabled ? .Horizontal : .Vertical
        }
    }
    
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
        self.delegate = self
        
        self.canCancelContentTouches = true
        self.delaysContentTouches = true
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        
        self.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.applyDefaultConfiguration()
    }
    
    private func applyDefaultConfiguration() {
        self.pagingEnabled = false
    }
    
    // MARK: - Adding
    
    func addItemOfType(type: ETNavigationItemType, withText text: String) -> UIView? {
        var subview: UIView?
        switch type {
        case .Label:
            let label = self.newLabel()
            label.text = text
            subview = label as UIView
        case .Button:
            if let button = self.newButton() {
                button.setTitle(text, forState: .Normal)
                subview = button as UIView
            }
        }
        self.updateContentSize()
        return subview
    }
    
    private func newLabel() -> UILabel {
        let label = UILabel(frame: CGRectZero)
        label.isAccessibilityElement = true
        label.font = UIFont.boldSystemFontOfSize(label.font.pointSize)
        label.textAlignment = .Center
        self.setUpSubview(label)
        return label
    }
    
    private func newButton() -> UIButton? {
        if !self.pagingEnabled { return nil }
        let button = UIButton(frame: CGRectZero)
        button.isAccessibilityElement = true
        button.titleLabel!.font = UIFont.boldSystemFontOfSize(button.titleLabel!.font.pointSize)
        button.titleLabel!.textAlignment = .Center
        self.setUpSubview(button)
        return button
    }

    private func setUpSubview(subview: UIView) {
        subview.isAccessibilityElement = true
        subview.setTranslatesAutoresizingMaskIntoConstraints(false)
        subview.sizeToFit()
        self.addSubview(subview)
        self.setUpSubviewLayout(subview)
    }
    
    private func setUpSubviewLayout(subview: UIView) {
        var constraints: [NSLayoutConstraint]!
        switch self.scrollOrientation {
        case .Horizontal:
            constraints = [
                NSLayoutConstraint(item: subview, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: subview, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1.0, constant: 0.0)
            ]
            var index: Int = self.subviews.count - 1
            var leftConstraint: NSLayoutConstraint!
            if index > 0 {
                let previousSibling = self.subviews[index - 1] as UIView
                leftConstraint = NSLayoutConstraint(item: subview, attribute: .Leading, relatedBy: .Equal, toItem: previousSibling, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
            } else {
                leftConstraint = NSLayoutConstraint(item: subview, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 0.0)
            }
            constraints.append(leftConstraint)
        case .Vertical:
            println("TODO")
        }
        self.addConstraints(constraints)
    }
    
    // MARK: - Updating

    func updateVisibleItem() {
        if let visibleItem = self.visibleItem {
            for subview in self.subviews as [UIView] {
                switch self.scrollOrientation {
                case .Horizontal:
                    if subview.frame.origin.x == self.contentOffset.x {
                        self.visibleItem = subview
                    }
                case .Vertical:
                    println("TODO")
                }
            }
        } else {
            self.visibleItem = self.subviews[0] as? UIView
        }
    }
    
    private func updateContentSize() {
        // NOTE: This is a mitigation for a defect in the scrollview-autolayout implementation.
        let makeshiftBounceTailRegionSize = self.frame.size.width * 0.4
        self.contentSize = CGSize(
            width: self.frame.size.width * CGFloat(self.subviews.count) + makeshiftBounceTailRegionSize,
            height: self.contentSize.height
        )
    }

    private func updateTextAppearance() {
        for subview in self.subviews as [UIView] {
            if let button = subview as? UIButton {
                button.setTitleColor(self.textColor, forState: .Normal)
            } else if let label = subview as? UILabel {
                label.textColor = self.textColor
            }
        }
    }
    
    // MARK: - UIScrollView
    
    override func touchesShouldCancelInContentView(view: UIView!) -> Bool {
        if view is UIButton {
            return true
        }
        return super.touchesShouldCancelInContentView(view)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView!) {
        self.updateVisibleItem()
    }
    
}

// MARK: - Wrapper

@objc(ETNavigationTitlePickerView) class NavigationTitlePickerView : UIView {
    
    var scrollView: NavigationTitleScrollView!

    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.scrollView = NavigationTitleScrollView(frame: frame)
        self.setUp()
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scrollView = NavigationTitleScrollView(coder: aDecoder)
        self.setUp()
    }
    
    private func setUp() {
        self.userInteractionEnabled = true
        
        self.scrollView.pagingEnabled = true
        self.addSubview(self.scrollView)
        let constraints = [
            NSLayoutConstraint(item: self.scrollView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.scrollView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.scrollView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 110.0),
            NSLayoutConstraint(item: self.scrollView, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 1.0, constant: 0.0)
        ]
        self.addConstraints(constraints)
        
        self.setUpMasking()
    }
    
    // MARK: - Wrappers

    var delegate: NavigationTitlePickerViewDelegate? {
        get { return self.scrollView.pickerViewDelegate }
        set(newValue) { self.scrollView.pickerViewDelegate = newValue }
    }

    var textColor: UIColor {
        get { return self.scrollView.textColor }
        set(newValue) { self.scrollView.textColor = newValue }
    }
    
    var items: [UIView] { return self.scrollView.subviews as [UIView] }

    var visibleItem: UIView? {
        get { return self.scrollView.visibleItem }
        set(newValue) { self.scrollView.visibleItem = newValue }
    }

    func addItemOfType(type: ETNavigationItemType, withText text: String) -> UIView? {
        return self.scrollView.addItemOfType(type, withText: text)
    }

    func updateVisibleItem() {
        self.scrollView.updateVisibleItem()
    }
    
    // MARK: - Masking
    
    private var whiteColor: CGColor { return UIColor.whiteColor().CGColor }
    private var clearColor: CGColor { return UIColor.clearColor().CGColor }
    
    private func setUpMasking() {
        let maskLayer = CAGradientLayer()
        maskLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        maskLayer.masksToBounds = true
        maskLayer.colors = [self.clearColor, self.whiteColor, self.whiteColor, self.clearColor] as [AnyObject]
        maskLayer.locations = [0.0, 0.2, 0.8, 1.0]
        maskLayer.frame = self.bounds
        self.layer.mask = maskLayer
    }

}