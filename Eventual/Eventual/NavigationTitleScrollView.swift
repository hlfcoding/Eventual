//
//  NavigationTitleScrollView.swift
//  Eventual
//
//  Created by Peng Wang on 8/1/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import QuartzCore

enum NavigationTitleItemType {
    case Label, Button
}

enum ScrollOrientation {
    case Horizontal, Vertical
}

// MARK: - Protocols

protocol NavigationTitleScrollViewDelegate: NSObjectProtocol {

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, didChangeVisibleItem visibleItem: UIView)

}

protocol NavigationTitleScrollViewDataSource: NSObjectProtocol {

    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView?

}

class NavigationTitleScrollViewFixture: NSObject, NavigationTitleScrollViewDataSource {

    func navigationTitleScrollViewItemCount(scrollView: NavigationTitleScrollView) -> Int {
        return 1
    }

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, itemAtIndex index: Int) -> UIView? {
        return scrollView.newItemOfType(.Label, withText: "Title Item")
    }

}

// MARK: - Main

@IBDesignable class NavigationTitleScrollView: UIScrollView, NavigationTitleViewProtocol, UIScrollViewDelegate
{
    @IBInspectable var fontSize: CGFloat = 17.0

    weak var scrollViewDelegate: NavigationTitleScrollViewDelegate?

    weak var dataSource: NavigationTitleScrollViewDataSource? {
        didSet {
            if self.dataSource != nil {
                self.refreshSubviews()
            }
        }
    }

    dynamic var textColor: UIColor! {
        didSet {
            self.updateTextAppearance()
        }
    }

    var items: [UIView] { return self.subviews }

    var visibleItem: UIView? {
        didSet {
            guard let visibleItem = self.visibleItem where visibleItem != oldValue else { return }
            if self.pagingEnabled {
                self.layoutIfNeeded()
                self.setContentOffset(
                    CGPoint(x: visibleItem.frame.origin.x, y: self.contentOffset.y),
                    animated: true
                )
            }
            if oldValue != nil, let delegate = self.scrollViewDelegate {
                delegate.navigationTitleScrollView(self, didChangeVisibleItem: visibleItem)
            }
        }
    }

    var scrollOrientation: ScrollOrientation = .Vertical

    override var pagingEnabled: Bool {
        didSet {
            self.scrollEnabled = self.pagingEnabled
            self.clipsToBounds = !self.pagingEnabled
            self.scrollOrientation = self.pagingEnabled ? .Horizontal : .Vertical
            self.translatesAutoresizingMaskIntoConstraints = !self.pagingEnabled
        }
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }

    override func prepareForInterfaceBuilder() {
        self.dataSource = NavigationTitleScrollViewFixture()
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

    func newItemOfType(type: NavigationTitleItemType, withText text: String) -> UIView? {
        var subview: UIView?
        switch type {
        case .Label:
            let label = self.newLabel()
            label.text = text
            subview = label as UIView
        case .Button:
            guard let button = self.newButton() else { break }
            button.setTitle(text, forState: .Normal)
            subview = button as UIView
        }
        return subview
    }

    private func newLabel() -> UILabel {
        let label = UILabel(frame: CGRectZero)
        label.font = UIFont.boldSystemFontOfSize(self.fontSize)
        label.textAlignment = .Center
        label.textColor = self.textColor
        label.isAccessibilityElement = true
        self.setUpSubview(label)
        return label
    }

    private func newButton() -> UIButton? {
        guard self.pagingEnabled else { return nil }
        let button = UIButton(frame: CGRectZero)
        button.titleLabel!.font = UIFont.boldSystemFontOfSize(self.fontSize)
        button.titleLabel!.textAlignment = .Center
        button.titleLabel!.textColor = self.textColor
        self.setUpSubview(button)
        return button
    }

    private func setUpSubview(subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.sizeToFit()
    }

    private func setUpSubviewLayout(subview: UIView) {
        var constraints: [NSLayoutConstraint]!
        let index: Int = self.subviews.count - 1
        switch self.scrollOrientation {
        case .Horizontal:
            constraints = [
                NSLayoutConstraint(item: subview, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: subview, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1.0, constant: 0.0)
            ]
            let leftConstraint: NSLayoutConstraint!
            if index > 0 {
                let previousSibling = self.subviews[index - 1]
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
            let topConstraint: NSLayoutConstraint!
            if index > 0 {
                let previousSibling = self.subviews[index - 1]
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
        guard let dataSource = self.dataSource else { return }
        for view in self.subviews { view.removeFromSuperview() }
        let count = dataSource.navigationTitleScrollViewItemCount(self)
        for i in 0..<count {
            guard let subview = dataSource.navigationTitleScrollView(self, itemAtIndex: i) else {
                print("WARNING: Failed to add item.")
                continue
            }
            self.addSubview(subview)
            self.setUpSubviewLayout(subview)
            self.updateContentSize()
        }
    }

    func updateVisibleItem() {
        guard self.visibleItem != nil else {
            self.visibleItem = self.subviews[0]
            return
        }
        for subview in self.subviews where self.isSubviewVisible(subview){
            self.visibleItem = subview
            break
        }
    }

    private func isSubviewVisible(subview: UIView) -> Bool {
        switch self.scrollOrientation {
        case .Horizontal:
            return (self.contentOffset.x >= subview.frame.origin.x &&
                    self.contentOffset.x < subview.frame.origin.x + subview.frame.size.width)
        case .Vertical:
            return (self.contentOffset.y >= subview.frame.origin.y &&
                    self.contentOffset.y < subview.frame.origin.y + subview.frame.size.height)
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
        for subview in self.subviews {
            if let button = subview as? UIButton {
                button.setTitleColor(self.textColor, forState: .Normal)
            } else if let label = subview as? UILabel {
                label.textColor = self.textColor
            }
        }
    }

    // MARK: - UIScrollView

    override func touchesShouldCancelInContentView(view: UIView) -> Bool {
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

@IBDesignable class NavigationTitlePickerView: UIView, NavigationTitleViewProtocol
{

    @IBInspectable var maskColor: UIColor = UIColor.whiteColor()
    @IBInspectable var maskRatio: CGFloat = 0.2
    @IBInspectable var fontSize: CGFloat! {
        get { return self.scrollView.fontSize }
        set(newValue) { self.scrollView.fontSize = newValue }
    }

    var scrollView: NavigationTitleScrollView!

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.scrollView = NavigationTitleScrollView(frame: frame)
        self.setUp()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.scrollView = NavigationTitleScrollView(coder: aDecoder)
        self.setUp()
    }

    override func prepareForInterfaceBuilder() {
        // FIXME: Ideally the below should work. Too bad (text doesn't show).
        // self.scrollView.prepareForInterfaceBuilder()
    }

    private func setUp() {
        self.fontSize = 16.0
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

    dynamic var textColor: UIColor! {
        get { return self.scrollView.textColor }
        set(newValue) { self.scrollView.textColor = newValue }
    }

    var items: [UIView] {
        return self.scrollView.subviews as [UIView]
    }

    var visibleItem: UIView? {
        get { return self.scrollView.visibleItem }
        set(newValue) { self.scrollView.visibleItem = newValue }
    }

    func newItemOfType(type: NavigationTitleItemType, withText text: String) -> UIView? {
        return self.scrollView.newItemOfType(type, withText: text)
    }

    func updateVisibleItem() {
        self.scrollView.updateVisibleItem()
    }

    // MARK: - Masking

    private func setUpMasking() {
        let clearColor = UIColor.clearColor().CGColor
        let maskColor = self.maskColor.CGColor
        let maskLayer = CAGradientLayer()
        maskLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        maskLayer.masksToBounds = true
        maskLayer.colors = [clearColor, maskColor, maskColor, clearColor] as [AnyObject]
        maskLayer.locations = [0.0, self.maskRatio, 1.0 - self.maskRatio, 1.0]
        maskLayer.frame = self.bounds
        self.layer.mask = maskLayer
    }

}