//
//  TitleScrollView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import QuartzCore

enum TitleItemType {

    case label, button

}

enum ScrollOrientation {

    case horizontal, vertical

}

enum TitleScrollViewContext: String {

    case navigationBar

}

// MARK: - Protocols

protocol TitleViewProtocol {

    var textColor: UIColor! { get set }

}

@objc protocol TitleScrollViewDelegate: NSObjectProtocol {

    @objc optional func titleScrollViewContext(_ scrollView: TitleScrollView) -> String

    func titleScrollView(_ scrollView: TitleScrollView, didChangeVisibleItem visibleItem: UIView)

    @objc optional func titleScrollView(_ scrollView: TitleScrollView,
                                        didReceiveControlEvents controlEvents: UIControlEvents,
                                        forItem item: UIControl)

}

protocol TitleScrollViewDataSource: NSObjectProtocol {

    func titleScrollViewItemCount(_ scrollView: TitleScrollView) -> Int

    func titleScrollView(_ scrollView: TitleScrollView, itemAt index: Int) -> UIView?

}

class TitleScrollViewFixture: NSObject, TitleScrollViewDataSource {

    func titleScrollViewItemCount(_ scrollView: TitleScrollView) -> Int {
        return 1
    }

    func titleScrollView(_ scrollView: TitleScrollView, itemAt index: Int) -> UIView? {
        return scrollView.newItem(type: .label, text: "Title Item")
    }

}

// MARK: - Main

@IBDesignable class TitleScrollView: UIScrollView, TitleViewProtocol, UIScrollViewDelegate {

    @IBInspectable var fontSize: CGFloat = 17

    weak var scrollViewDelegate: TitleScrollViewDelegate?

    weak var dataSource: TitleScrollViewDataSource? {
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
            guard let visibleItem = visibleItem, visibleItem != oldValue else { return }
            if isPagingEnabled {
                layoutIfNeeded()
                setContentOffset(
                    CGPoint(x: visibleItem.frame.origin.x, y: contentOffset.y),
                    animated: true
                )
            }
            if let _ = oldValue, let delegate = scrollViewDelegate {
                delegate.titleScrollView(self, didChangeVisibleItem: visibleItem)
            }
        }
    }

    var scrollOrientation: ScrollOrientation = .vertical

    override var isPagingEnabled: Bool {
        didSet {
            isScrollEnabled = isPagingEnabled
            clipsToBounds = !isPagingEnabled
            scrollOrientation = isPagingEnabled ? .horizontal : .vertical
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
        dataSource = TitleScrollViewFixture()
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
        isPagingEnabled = false
    }

    // MARK: - Actions

    @objc private func handleTap(forButton button: UIControl) {
        guard let delegate = scrollViewDelegate else { return }
        delegate.titleScrollView?(self, didReceiveControlEvents: .touchUpInside, forItem: button)
    }

    // MARK: - Creating

    func newItem(type: TitleItemType, text: String) -> UIView? {
        var subview: UIView?
        switch type {
        case .label:
            let label = newLabel()
            label.text = text
            subview = label as UIView
        case .button:
            guard let button = newButton() else { break }
            button.setTitle(text, for: .normal)
            button.addTarget(self, action: #selector(handleTap(forButton:)), for: .touchUpInside)
            subview = button as UIView
        }
        return subview
    }

    private func newLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.font = UIFont.boldSystemFont(ofSize: fontSize)
        label.textAlignment = .center
        label.textColor = textColor
        label.isAccessibilityElement = true
        setUpSubview(label)
        return label
    }

    private func newButton() -> UIButton? {
        guard isPagingEnabled else { return nil }
        let button = UIButton(frame: .zero)
        button.titleLabel!.font = UIFont.boldSystemFont(ofSize: fontSize)
        button.titleLabel!.textAlignment = .center
        button.titleLabel!.textColor = textColor
        setUpSubview(button)
        return button
    }

    private func setUpSubview(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.sizeToFit()
    }

    private func setUpLayout(for subview: UIView) {
        var constraints: [NSLayoutConstraint]!
        let index = subviews.count - 1
        let isFirst = index == 0
        switch scrollOrientation {
        case .horizontal:
            constraints = [
                subview.centerYAnchor.constraint(equalTo: centerYAnchor),
                subview.widthAnchor.constraint(equalTo: widthAnchor),
                (isFirst ?
                    subview.leftAnchor.constraint(equalTo: leftAnchor) :
                    subview.leadingAnchor.constraint(equalTo: subviews[index - 1].trailingAnchor)
                ),
            ]
        case .vertical:
            constraints = [
                subview.centerXAnchor.constraint(equalTo: centerXAnchor),
                subview.heightAnchor.constraint(equalTo: heightAnchor),
                (isFirst ?
                    subview.topAnchor.constraint(equalTo: topAnchor) :
                    subview.topAnchor.constraint(equalTo: subviews[index - 1].bottomAnchor)
                ),
            ]
        }
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updating

    func refreshSubviews() {
        guard let dataSource = dataSource else { return }
        for view in subviews { view.removeFromSuperview() }
        let count = dataSource.titleScrollViewItemCount(self)
        for i in 0..<count {
            guard let subview = dataSource.titleScrollView(self, itemAt: i) else {
                print("WARNING: Failed to add item.")
                continue
            }
            addSubview(subview)
            setUpLayout(for: subview)
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

    private func isSubviewVisible(_ subview: UIView) -> Bool {
        let frame = subview.frame
        switch scrollOrientation {
        case .horizontal:
            return (contentOffset.x >= frame.origin.x && contentOffset.x < frame.origin.x + frame.width)
        case .vertical:
            return (contentOffset.y >= frame.origin.y && contentOffset.y < frame.origin.y + frame.height)
        }
    }

    private func updateContentSize() {
        switch scrollOrientation {
        case .horizontal:
            // NOTE: This is a mitigation for a defect in the scrollview-autolayout implementation.
            let makeshiftBounceTailRegionSize = frame.width * 0.4
            contentSize = CGSize(
                width: frame.width * CGFloat(subviews.count) + makeshiftBounceTailRegionSize,
                height: contentSize.height
            )
        case .vertical:
            contentSize = CGSize(
                width: frame.width,
                height: frame.height * CGFloat(subviews.count)
            )
        }
    }

    private func updateTextAppearance() {
        for subview in subviews {
            if let button = subview as? UIButton {
                button.setTitleColor(textColor, for: .normal)
            } else if let label = subview as? UILabel {
                label.textColor = textColor
            }
        }
    }

    // MARK: - UIScrollView

    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIButton {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateVisibleItem()
    }

}

// MARK: - Wrapper

@IBDesignable class TitleMaskedScrollView: UIView, TitleViewProtocol {

    @IBInspectable var maskColor: UIColor = UIColor.white
    @IBInspectable var maskRatio: CGFloat = 0.2
    @IBInspectable var fontSize: CGFloat! {
        get { return scrollView.fontSize }
        set(newValue) { scrollView.fontSize = newValue }
    }

    var scrollView: TitleScrollView!

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView = TitleScrollView(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scrollView = TitleScrollView(coder: aDecoder)
    }

    override func prepareForInterfaceBuilder() {
        // FIXME: Ideally the below should work. Too bad (text doesn't show).
        // scrollView.prepareForInterfaceBuilder()
    }

    func setUp() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.centerXAnchor.constraint(equalTo: centerXAnchor),
            scrollView.centerYAnchor.constraint(equalTo: centerYAnchor),
            scrollView.heightAnchor.constraint(equalTo: heightAnchor),
        ])
        switch scrollView.scrollOrientation {
        case .horizontal:
            guard let delegate = delegate else { preconditionFailure() }
            guard let rawValue = delegate.titleScrollViewContext?(scrollView),
                let context = TitleScrollViewContext(rawValue: rawValue) else {
                scrollView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
                break
            }
            switch context {
            case .navigationBar:
                scrollView.widthAnchor.constraint(equalToConstant: 110).isActive = true
            }
        case .vertical:
            scrollView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        }

        let clearColor = UIColor.clear.cgColor
        let maskColor = self.maskColor.cgColor
        let maskLayer = CAGradientLayer()
        maskLayer.colors = [clearColor, maskColor, maskColor, clearColor] as [Any]
        maskLayer.masksToBounds = true
        let maskRatio = Float(self.maskRatio)
        switch scrollView.scrollOrientation {
        case .horizontal:
            maskLayer.locations = [0, NSNumber(value: maskRatio), NSNumber(value: 1 - maskRatio), 1]
            maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
            maskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        case .vertical:
            maskLayer.locations = [0, NSNumber(value: 2 * maskRatio), NSNumber(value: 1 - 2 * maskRatio), 1]
            maskLayer.startPoint = CGPoint(x: 0.5, y: 0)
            maskLayer.endPoint = CGPoint(x: 0.5, y: 1)
        }
        layer.mask = maskLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.mask?.frame = bounds
    }

    // MARK: - Wrappers

    weak var delegate: TitleScrollViewDelegate? {
        get { return scrollView.scrollViewDelegate }
        set(newValue) { scrollView.scrollViewDelegate = newValue }
    }

    weak var dataSource: TitleScrollViewDataSource? {
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

@IBDesignable class TitlePickerView: TitleMaskedScrollView
{
    // MARK: - Initializers

    override func setUp() {
        scrollView.isPagingEnabled = true
        super.setUp()

        fontSize = 16
    }

    // MARK: - UIView

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled else { return nil }
        // Work around UIScrollView width (and hitbox) being tied to page-size when pagingEnabled.
        guard point.x >= 0 && point.x <= bounds.width else { return nil }

        let scrollViewPoint = convert(point, to: scrollView)
        var descendantView = scrollView.hitTest(scrollViewPoint, with: event)
        descendantView = descendantView ?? scrollView
        return descendantView
    }
    
}
