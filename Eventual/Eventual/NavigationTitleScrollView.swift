//
//  NavigationTitleScrollView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
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

@objc protocol NavigationTitleScrollViewDelegate: NSObjectProtocol {

    func navigationTitleScrollView(scrollView: NavigationTitleScrollView, didChangeVisibleItem visibleItem: UIView)

    optional func navigationTitleScrollView(scrollView: NavigationTitleScrollView,
                                            didReceiveControlEvents controlEvents: UIControlEvents,
                                            forItem item: UIControl)

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
    @IBInspectable var fontSize: CGFloat = 17

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

    // MARK: - Actions

    @objc @IBAction private func handleButtonTap(button: UIControl) {
        guard let delegate = self.scrollViewDelegate else { return }
        delegate.navigationTitleScrollView?(self, didReceiveControlEvents: .TouchUpInside, forItem: button)
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
            button.addTarget(self, action: #selector(handleButtonTap(_:)), forControlEvents: .TouchUpInside)
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
        let index = self.subviews.count - 1
        let isFirst = index == 0
        switch self.scrollOrientation {
        case .Horizontal:
            constraints = [
                subview.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor),
                subview.widthAnchor.constraintEqualToAnchor(self.widthAnchor),
                (isFirst ?
                    subview.leftAnchor.constraintEqualToAnchor(self.leftAnchor) :
                    subview.leadingAnchor.constraintEqualToAnchor(self.subviews[index - 1].trailingAnchor)
                )
            ]
        case .Vertical:
            constraints = [
                subview.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor),
                subview.heightAnchor.constraintEqualToAnchor(self.heightAnchor),
                (isFirst ?
                    subview.topAnchor.constraintEqualToAnchor(self.topAnchor) :
                    subview.topAnchor.constraintEqualToAnchor(self.subviews[index - 1].bottomAnchor)
                )
            ]
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
        let frame = subview.frame
        switch self.scrollOrientation {
        case .Horizontal:
            return (self.contentOffset.x >= frame.origin.x &&
                    self.contentOffset.x < frame.origin.x + frame.width)
        case .Vertical:
            return (self.contentOffset.y >= frame.origin.y &&
                    self.contentOffset.y < frame.origin.y + frame.height)
        }
    }

    private func updateContentSize() {
        switch self.scrollOrientation {
        case .Horizontal:
            // NOTE: This is a mitigation for a defect in the scrollview-autolayout implementation.
            let makeshiftBounceTailRegionSize = self.frame.width * 0.4
            self.contentSize = CGSize(
                width: self.frame.width * CGFloat(self.subviews.count) + makeshiftBounceTailRegionSize,
                height: self.contentSize.height
            )
        case .Vertical:
            self.contentSize = CGSize(
                width: self.frame.width,
                height: self.frame.height * CGFloat(self.subviews.count)
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
        self.fontSize = 16

        self.scrollView.pagingEnabled = true
        self.addSubview(self.scrollView)
        self.addConstraints([
            self.scrollView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor),
            self.scrollView.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor),
            self.scrollView.widthAnchor.constraintEqualToConstant(110),
            self.scrollView.heightAnchor.constraintEqualToAnchor(self.heightAnchor)
        ])

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
        let clearColor = UIColor.clearColor().CGColor, maskColor = self.maskColor.CGColor
        let maskLayer = CAGradientLayer()
        maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        maskLayer.masksToBounds = true
        maskLayer.colors = [clearColor, maskColor, maskColor, clearColor] as [AnyObject]
        maskLayer.locations = [0, self.maskRatio, 1 - self.maskRatio, 1]
        maskLayer.frame = self.bounds
        self.layer.mask = maskLayer
    }

    // MARK: - UIView

    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let scrollViewPoint = self.convertPoint(point, toView: self.scrollView)
        var descendantView = self.scrollView.hitTest(scrollViewPoint, withEvent: event)
        // Work around UIScrollView width (and hitbox) being tied to page-size when pagingEnabled.
        descendantView = descendantView ?? self.scrollView
        return descendantView
    }
    
}
