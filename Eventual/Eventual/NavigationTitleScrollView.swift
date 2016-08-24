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

protocol NavigationTitleViewProtocol {

    var textColor: UIColor! { get set }

}

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

@IBDesignable class NavigationTitleScrollView: UIScrollView, NavigationTitleViewProtocol, UIScrollViewDelegate {

    @IBInspectable var fontSize: CGFloat = 17

    weak var scrollViewDelegate: NavigationTitleScrollViewDelegate?

    weak var dataSource: NavigationTitleScrollViewDataSource? {
        didSet {
            guard let _ = dataSource else { return }
            refreshSubviews()
        }
    }

    dynamic var textColor: UIColor! {
        didSet {
            updateTextAppearance()
        }
    }

    var items: [UIView] { return subviews }

    var visibleItem: UIView? {
        didSet {
            guard let visibleItem = visibleItem where visibleItem != oldValue else { return }
            if pagingEnabled {
                layoutIfNeeded()
                setContentOffset(
                    CGPoint(x: visibleItem.frame.origin.x, y: contentOffset.y),
                    animated: true
                )
            }
            if let _ = oldValue, delegate = scrollViewDelegate {
                delegate.navigationTitleScrollView(self, didChangeVisibleItem: visibleItem)
            }
        }
    }

    var scrollOrientation: ScrollOrientation = .Vertical

    override var pagingEnabled: Bool {
        didSet {
            scrollEnabled = pagingEnabled
            clipsToBounds = !pagingEnabled
            scrollOrientation = pagingEnabled ? .Horizontal : .Vertical
        }
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override func prepareForInterfaceBuilder() {
        dataSource = NavigationTitleScrollViewFixture()
    }

    private func setUp() {
        delegate = self

        canCancelContentTouches = true
        delaysContentTouches = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false

        applyDefaultConfiguration()
    }

    private func applyDefaultConfiguration() {
        pagingEnabled = false
    }

    // MARK: - Actions

    @objc @IBAction private func handleButtonTap(button: UIControl) {
        guard let delegate = scrollViewDelegate else { return }
        delegate.navigationTitleScrollView?(self, didReceiveControlEvents: .TouchUpInside, forItem: button)
    }

    // MARK: - Creating

    func newItemOfType(type: NavigationTitleItemType, withText text: String) -> UIView? {
        var subview: UIView?
        switch type {
        case .Label:
            let label = newLabel()
            label.text = text
            subview = label as UIView
        case .Button:
            guard let button = newButton() else { break }
            button.setTitle(text, forState: .Normal)
            button.addTarget(self, action: #selector(handleButtonTap(_:)), forControlEvents: .TouchUpInside)
            subview = button as UIView
        }
        return subview
    }

    private func newLabel() -> UILabel {
        let label = UILabel(frame: CGRectZero)
        label.font = UIFont.boldSystemFontOfSize(fontSize)
        label.textAlignment = .Center
        label.textColor = textColor
        label.isAccessibilityElement = true
        setUpSubview(label)
        return label
    }

    private func newButton() -> UIButton? {
        guard pagingEnabled else { return nil }
        let button = UIButton(frame: CGRectZero)
        button.titleLabel!.font = UIFont.boldSystemFontOfSize(fontSize)
        button.titleLabel!.textAlignment = .Center
        button.titleLabel!.textColor = textColor
        setUpSubview(button)
        return button
    }

    private func setUpSubview(subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.sizeToFit()
    }

    private func setUpSubviewLayout(subview: UIView) {
        var constraints: [NSLayoutConstraint]!
        let index = subviews.count - 1
        let isFirst = index == 0
        switch scrollOrientation {
        case .Horizontal:
            constraints = [
                subview.centerYAnchor.constraintEqualToAnchor(centerYAnchor),
                subview.widthAnchor.constraintEqualToAnchor(widthAnchor),
                (isFirst ?
                    subview.leftAnchor.constraintEqualToAnchor(leftAnchor) :
                    subview.leadingAnchor.constraintEqualToAnchor(subviews[index - 1].trailingAnchor)
                ),
            ]
        case .Vertical:
            constraints = [
                subview.centerXAnchor.constraintEqualToAnchor(centerXAnchor),
                subview.heightAnchor.constraintEqualToAnchor(heightAnchor),
                (isFirst ?
                    subview.topAnchor.constraintEqualToAnchor(topAnchor) :
                    subview.topAnchor.constraintEqualToAnchor(subviews[index - 1].bottomAnchor)
                ),
            ]
        }
        NSLayoutConstraint.activateConstraints(constraints)
    }

    // MARK: - Updating

    func refreshSubviews() {
        guard let dataSource = dataSource else { return }
        for view in subviews { view.removeFromSuperview() }
        let count = dataSource.navigationTitleScrollViewItemCount(self)
        for i in 0..<count {
            guard let subview = dataSource.navigationTitleScrollView(self, itemAtIndex: i) else {
                print("WARNING: Failed to add item.")
                continue
            }
            addSubview(subview)
            setUpSubviewLayout(subview)
            updateContentSize()
        }
    }

    func updateVisibleItem() {
        guard visibleItem != nil else {
            visibleItem = subviews[0]
            return
        }
        for subview in subviews where isSubviewVisible(subview){
            visibleItem = subview
            break
        }
    }

    private func isSubviewVisible(subview: UIView) -> Bool {
        let frame = subview.frame
        switch scrollOrientation {
        case .Horizontal:
            return (contentOffset.x >= frame.origin.x && contentOffset.x < frame.origin.x + frame.width)
        case .Vertical:
            return (contentOffset.y >= frame.origin.y && contentOffset.y < frame.origin.y + frame.height)
        }
    }

    private func updateContentSize() {
        switch scrollOrientation {
        case .Horizontal:
            // NOTE: This is a mitigation for a defect in the scrollview-autolayout implementation.
            let makeshiftBounceTailRegionSize = frame.width * 0.4
            contentSize = CGSize(
                width: frame.width * CGFloat(subviews.count) + makeshiftBounceTailRegionSize,
                height: contentSize.height
            )
        case .Vertical:
            contentSize = CGSize(
                width: frame.width,
                height: frame.height * CGFloat(subviews.count)
            )
        }
    }

    private func updateTextAppearance() {
        for subview in subviews {
            if let button = subview as? UIButton {
                button.setTitleColor(textColor, forState: .Normal)
            } else if let label = subview as? UILabel {
                label.textColor = textColor
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
        updateVisibleItem()
    }

}

// MARK: - Wrapper

@IBDesignable class NavigationTitleMaskedScrollView: UIView, NavigationTitleViewProtocol {

    @IBInspectable var maskColor: UIColor = UIColor.whiteColor()
    @IBInspectable var maskRatio: CGFloat = 0.2
    @IBInspectable var fontSize: CGFloat! {
        get { return scrollView.fontSize }
        set(newValue) { scrollView.fontSize = newValue }
    }

    var scrollView: NavigationTitleScrollView!

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView = NavigationTitleScrollView(frame: frame)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scrollView = NavigationTitleScrollView(coder: aDecoder)
        setUp()
    }

    override func prepareForInterfaceBuilder() {
        // FIXME: Ideally the below should work. Too bad (text doesn't show).
        // scrollView.prepareForInterfaceBuilder()
    }

    private func setUp() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activateConstraints([
            scrollView.centerXAnchor.constraintEqualToAnchor(centerXAnchor),
            scrollView.centerYAnchor.constraintEqualToAnchor(centerYAnchor),
            scrollView.heightAnchor.constraintEqualToAnchor(heightAnchor),
        ])
        switch scrollView.scrollOrientation {
        case .Horizontal:
            scrollView.widthAnchor.constraintEqualToConstant(110).active = true
        case .Vertical:
            scrollView.widthAnchor.constraintEqualToAnchor(widthAnchor).active = true
        }

        let clearColor = UIColor.clearColor().CGColor, maskColor = self.maskColor.CGColor
        let maskLayer = CAGradientLayer()
        maskLayer.colors = [clearColor, maskColor, maskColor, clearColor] as [AnyObject]
        maskLayer.frame = bounds
        maskLayer.masksToBounds = true
        switch scrollView.scrollOrientation {
        case .Horizontal:
            maskLayer.locations = [0, maskRatio, 1 - maskRatio, 1]
            maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
            maskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        case .Vertical:
            maskLayer.locations = [0, 2 * maskRatio, 1 - 2 * maskRatio, 1]
            maskLayer.startPoint = CGPoint(x: 0.5, y: 0)
            maskLayer.endPoint = CGPoint(x: 0.5, y: 1)
        }
        layer.mask = maskLayer
    }

    // MARK: - Wrappers

    weak var delegate: NavigationTitleScrollViewDelegate? {
        get { return scrollView.scrollViewDelegate }
        set(newValue) { scrollView.scrollViewDelegate = newValue }
    }

    weak var dataSource: NavigationTitleScrollViewDataSource? {
        get { return scrollView.dataSource }
        set(newValue) { scrollView.dataSource = newValue }
    }

    dynamic var textColor: UIColor! {
        get { return scrollView.textColor }
        set(newValue) { scrollView.textColor = newValue }
    }

    var items: [UIView] {
        return scrollView.subviews as [UIView]
    }

    var visibleItem: UIView? {
        get { return scrollView.visibleItem }
        set(newValue) { scrollView.visibleItem = newValue }
    }

    func refreshSubviews() {
        scrollView.refreshSubviews()
    }

    func updateVisibleItem() {
        scrollView.updateVisibleItem()
    }

}

// MARK: - Control

@IBDesignable class NavigationTitlePickerView: NavigationTitleMaskedScrollView
{
    // MARK: UIAccessibility

    override var accessibilityHint: String? {
        didSet {
            scrollView.accessibilityHint = accessibilityHint
        }
    }
    override var accessibilityLabel: String? {
        didSet {
            scrollView.accessibilityLabel = accessibilityLabel
        }
    }

    // MARK: - Initializers

    override private func setUp() {
        scrollView.pagingEnabled = true
        super.setUp()

        fontSize = 16
    }

    // MARK: - UIView

    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        // Work around UIScrollView width (and hitbox) being tied to page-size when pagingEnabled.
        guard point.x >= 0 && point.x <= bounds.width else { return nil }

        let scrollViewPoint = convertPoint(point, toView: scrollView)
        var descendantView = scrollView.hitTest(scrollViewPoint, withEvent: event)
        descendantView = descendantView ?? scrollView
        return descendantView
    }
    
}
