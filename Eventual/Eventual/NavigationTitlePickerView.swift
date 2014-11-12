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

// MARK: - Delegate

@objc(ETNavigationTitlePickerViewDelegate) protocol NavigationTitlePickerViewDelegate : NSObjectProtocol {
    
    func navigationTitleView(titleView: NavigationTitlePickerView, didChangeVisibleItem visibleItem: UIView);
    
}

// MARK: - Main

@objc(ETNavigationTitlePickerScrollView) class NavigationTitlePickerScrollView : UIScrollView,
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
                self.setContentOffset(
                    CGPoint(x: visibleItem.frame.origin.x, y: self.contentOffset.y),
                    animated: true
                )
            }
            if let delegate = self.pickerViewDelegate {
                delegate.navigationTitleView(
                    (self.superview! as NavigationTitlePickerView),
                    didChangeVisibleItem: self.visibleItem!
                )
            }
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
        self.clipsToBounds = false
        self.scrollEnabled = true
        self.pagingEnabled = true
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.canCancelContentTouches = true
        self.delaysContentTouches = true
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
    }
    
    // MARK: - Adding
    
    func addItemOfType(type: ETNavigationItemType, withText text: String) -> UIView {
        var subview: UIView;
        switch type {
        case .Label:
            let label = self.newLabel()
            label.text = text
            subview = label as UIView
        case .Button:
            let button = self.newButton()
            button.setTitle(text, forState: .Normal)
            subview = button as UIView
        }
        subview.isAccessibilityElement = true
        subview.sizeToFit()
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
    
    private func newButton() -> UIButton {
        let button = UIButton(frame: CGRectZero)
        button.isAccessibilityElement = true
        button.titleLabel!.font = UIFont.boldSystemFontOfSize(button.titleLabel!.font.pointSize)
        button.titleLabel!.textAlignment = .Center
        self.setUpSubview(button)
        return button
    }

    private func setUpSubview(subview: UIView) {
        subview.setTranslatesAutoresizingMaskIntoConstraints(false)
        let subviews = self.subviews as [UIView]
        var index: Int! = find(subviews, subview)
        if index == nil {
            self.addSubview(subview)
            index = subviews.count
        }
        self.addConstraint(NSLayoutConstraint(
            item: subview, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0
        ))
        self.addConstraint(NSLayoutConstraint(
            item: subview, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1.0, constant: 0.0
        ))
        if self.subviews.count > 1 {
            let previousSibling = subviews[index - 1]
            self.addConstraint(NSLayoutConstraint(
                item: subview, attribute: .Leading, relatedBy: .Equal, toItem: previousSibling, attribute: .Trailing, multiplier: 1.0, constant: 0.0
            ))
        } else {
            self.addConstraint(NSLayoutConstraint(
                item: subview, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 0.0
            ))
        }
    }
    
    // MARK: - Updating

    func updateVisibleItem() {
        if let visibleItem = self.visibleItem {
            for subview in self.subviews as [UIView] {
                if subview.frame.origin.x == self.contentOffset.x {
                    self.visibleItem = subview
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
    
    private let throttleThresholdOffset: CGFloat = 1.0
    private var previousOffset: CGFloat = -1.0
    
    func scrollViewDidScroll(scrollView: UIScrollView!) {
        let offset = self.contentOffset.x
        if self.previousOffset != -1.0 && abs(offset - self.previousOffset) < self.throttleThresholdOffset { return }
        self.previousOffset = offset
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView!) {
        self.updateVisibleItem()
    }
    
}

// MARK: - Wrapper

@objc(ETNavigationTitlePickerView) class NavigationTitlePickerView : UIView {
    
    var scrollView: NavigationTitlePickerScrollView!

    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.scrollView = NavigationTitlePickerScrollView(frame: frame)
        self.setUp()
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scrollView = NavigationTitlePickerScrollView(coder: aDecoder)
        self.setUp()
    }
    
    private func setUp() {
        self.userInteractionEnabled = true
        self.addSubview(self.scrollView)
        self.addConstraint(NSLayoutConstraint(
            item: self.scrollView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0
        ))
        self.addConstraint(NSLayoutConstraint(
            item: self.scrollView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0
        ))
        self.addConstraint(NSLayoutConstraint(
            item: self.scrollView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 110.0
        ))
        self.addConstraint(NSLayoutConstraint(
            item: self.scrollView, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 1.0, constant: 0.0
        ))
        self.scrollView.setUp()
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

    func addItemOfType(type: ETNavigationItemType, withText text: String) -> UIView {
        return self.scrollView.addItemOfType(type, withText: text)
    }

    func updateVisibleItem() {
        self.scrollView.updateVisibleItem()
    }

}