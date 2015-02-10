//
//  NavigationTitleScrollView.swift
//  Eventual
//
//  Created by Peng Wang on 8/1/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import QuartzCore

enum ETNavigationTitleItemType {
    case Label, Button
}

enum ETScrollOrientation {
    case Horizontal, Vertical
}

// MARK: - Protocols

@objc(ETNavigationTitleScrollViewDelegate) protocol NavigationTitleScrollViewDelegate: class, NSObjectProtocol {
    
    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, didChangeVisibleItem visibleItem: UIView)
    
}

@objc(ETNavigationTitleScrollViewDataSource) protocol NavigationTitleScrollViewDataSource: class, NSObjectProtocol {
    
    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int
    
    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView?
    
}

// MARK: - Main

@objc(ETNavigationTitleScrollView) class NavigationTitleScrollView: UIScrollView,
    NavigationTitleViewProtocol, UIScrollViewDelegate
{
    
    weak var scrollViewDelegate: NavigationTitleScrollViewDelegate?
    
    weak var dataSource: NavigationTitleScrollViewDataSource? {
        didSet {
            if let dataSource = self.dataSource {
                self.refreshSubviews()
            }
        }
    }
    
    var textColor: UIColor! {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.updateTextAppearance()
            }
        }
    }

    var items: [UIView] { return self.subviews as! [UIView] }

    var visibleItem: UIView? {
        didSet {
            if self.visibleItem == oldValue { return }
            if let visibleItem = self.visibleItem {
                if self.pagingEnabled {
                    self.layoutIfNeeded()
                    self.setContentOffset(
                        CGPoint(x: visibleItem.frame.origin.x, y: self.contentOffset.y),
                        animated: true
                    )
                }
            }
            if let delegate = self.scrollViewDelegate {
                if oldValue != nil {
                    delegate.navigationTitleScrollView(self, didChangeVisibleItem: self.visibleItem!)
                }
            }
        }
    }
    
    var scrollOrientation: ETScrollOrientation = .Vertical

    override var pagingEnabled: Bool {
        didSet {
            self.scrollEnabled = self.pagingEnabled
            self.clipsToBounds = !self.pagingEnabled
            self.scrollOrientation = self.pagingEnabled ? .Horizontal : .Vertical
            self.setTranslatesAutoresizingMaskIntoConstraints(!self.pagingEnabled)
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
        
        self.applyDefaultConfiguration()
    }
    
    private func applyDefaultConfiguration() {
        self.pagingEnabled = false
    }
    
    // MARK: - Creating
    
    func newItemOfType(type: ETNavigationTitleItemType, withText text: String) -> UIView? {
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
        return subview
    }
    
    private func newLabel() -> UILabel {
        let label = UILabel(frame: CGRectZero)
        label.isAccessibilityElement = true
        label.font = UIFont.boldSystemFontOfSize(label.font.pointSize)
        label.textAlignment = .Center
        label.textColor = self.textColor
        self.setUpSubview(label)
        return label
    }
    
    private func newButton() -> UIButton? {
        if !self.pagingEnabled { return nil }
        let button = UIButton(frame: CGRectZero)
        button.isAccessibilityElement = true
        button.titleLabel!.font = UIFont.boldSystemFontOfSize(button.titleLabel!.font.pointSize)
        button.titleLabel!.textAlignment = .Center
        button.titleLabel!.textColor = self.textColor
        self.setUpSubview(button)
        return button
    }

    private func setUpSubview(subview: UIView) {
        subview.isAccessibilityElement = true
        subview.setTranslatesAutoresizingMaskIntoConstraints(false)
        subview.sizeToFit()
    }
    
    private func setUpSubviewLayout(subview: UIView) {
        var constraints: [NSLayoutConstraint]!
        var index: Int = self.subviews.count - 1
        switch self.scrollOrientation {
        case .Horizontal:
            constraints = [
                NSLayoutConstraint(item: subview, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: subview, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1.0, constant: 0.0)
            ]
            var leftConstraint: NSLayoutConstraint!
            if index > 0 {
                let previousSibling = self.subviews[index - 1] as! UIView
                leftConstraint = NSLayoutConstraint(item: subview, attribute: .Leading, relatedBy: .Equal, toItem: previousSibling, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
            } else {
                leftConstraint = NSLayoutConstraint(item: subview, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 0.0)
            }
            constraints.append(leftConstraint)
        case .Vertical:
            constraints = [
                NSLayoutConstraint(item: subview, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: subview, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 1.0, constant: 0.0)
            ]
            var topConstraint: NSLayoutConstraint!
            if index > 0 {
                let previousSibling = self.subviews[index - 1] as! UIView
                topConstraint = NSLayoutConstraint(item: subview, attribute: .Top, relatedBy: .Equal, toItem: previousSibling, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
            } else {
                topConstraint = NSLayoutConstraint(item: subview, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0)
            }
            constraints.append(topConstraint)
        }
        self.addConstraints(constraints)
    }
    
    // MARK: - Updating

    func refreshSubviews() {
        if let dataSource = self.dataSource {
            for view in self.subviews { view.removeFromSuperview() }
            let count = dataSource.navigationTitleScrollViewItemCount(self)
            for i in 0..<count {
                if let subview = dataSource.navigationTitleScrollView(self, itemAtIndex: i) {
                    self.addSubview(subview)
                    self.setUpSubviewLayout(subview)
                    self.updateContentSize()
                } else {
                    println("WARNING: Failed to add item.")
                }
            }
        }
    }
    
    func updateVisibleItem() {
        if let visibleItem = self.visibleItem {
            for subview in self.subviews as! [UIView] {
                switch self.scrollOrientation {
                case .Horizontal:
                    if self.contentOffset.x >= subview.frame.origin.x &&
                       self.contentOffset.x <= subview.frame.origin.x + subview.frame.size.width
                    {
                        self.visibleItem = subview
                    }
                case .Vertical:
                    if self.contentOffset.y >= subview.frame.origin.y &&
                       self.contentOffset.y <= subview.frame.origin.y + subview.frame.size.height
                    {
                        self.visibleItem = subview
                    }
                }
            }
        } else {
            self.visibleItem = self.subviews[0] as? UIView
        }
    }
    
    private func updateContentSize() {
        switch self.scrollOrientation {
        case .Horizontal:
            // NOTE: This is a mitigation for a defect in the scrollview-autolayout implementation.
            let makeshiftBounceTailRegionSize = self.frame.size.width * 0.4
            self.contentSize = CGSize(
                width: self.frame.size.width * CGFloat(self.subviews.count) + makeshiftBounceTailRegionSize,
                height: self.contentSize.height
            )
        case .Vertical:
            self.contentSize = CGSize(
                width: self.frame.size.width,
                height: self.frame.size.height * CGFloat(self.subviews.count)
            )
        }
    }

    private func updateTextAppearance() {
        for subview in self.subviews as! [UIView] {
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
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.updateVisibleItem()
    }
    
}

// MARK: - Wrapper

@objc(ETNavigationTitlePickerView) class NavigationTitlePickerView: UIView,
    NavigationTitleViewProtocol
{
    
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

    weak var delegate: NavigationTitleScrollViewDelegate? {
        get { return self.scrollView.scrollViewDelegate }
        set(newValue) { self.scrollView.scrollViewDelegate = newValue }
    }
    
    weak var dataSource: NavigationTitleScrollViewDataSource? {
        get { return self.scrollView.dataSource }
        set(newValue) { self.scrollView.dataSource = newValue }
    }

    var textColor: UIColor {
        get { return self.scrollView.textColor }
        set(newValue) { self.scrollView.textColor = newValue }
    }
    
    var items: [UIView] { return self.scrollView.subviews as! [UIView] }

    var visibleItem: UIView? {
        get { return self.scrollView.visibleItem }
        set(newValue) { self.scrollView.visibleItem = newValue }
    }

    func newItemOfType(type: ETNavigationTitleItemType, withText text: String) -> UIView? {
        return self.scrollView.newItemOfType(type, withText: text)
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