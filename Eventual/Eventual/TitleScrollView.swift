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

protocol TitleScrollViewDataSource: NSObjectProtocol {

    func titleScrollViewItemCount(_ scrollView: TitleScrollView) -> Int

    func titleScrollView(_ scrollView: TitleScrollView, itemAt index: Int) -> UIView?

}

@objc protocol TitleScrollViewDelegate: NSObjectProtocol {

    @objc optional func titleScrollViewContext(_ scrollView: TitleScrollView) -> String

    func titleScrollView(_ scrollView: TitleScrollView, didChangeVisibleItem visibleItem: UIView)

    @objc optional func titleScrollView(_ scrollView: TitleScrollView,
                                        didReceiveControlEvents controlEvents: UIControlEvents,
                                        forItem item: UIControl)

}

protocol TitleScrollViewProxy: class {

    var scrollView: TitleScrollView! { get }

    weak var dataSource: TitleScrollViewDataSource? { get set }
    weak var delegate: TitleScrollViewDelegate? { get set }

    var textColor: UIColor! { get set }

    var items: [UIView] { get }
    var visibleItem: UIView? { get set }

    var accessibilityHint: String? { get set }
    var accessibilityLabel: String? { get set }

    func refreshItems()
    func updateVisibleItem()

}

extension TitleScrollViewProxy {

    weak var dataSource: TitleScrollViewDataSource? {
        get { return scrollView.dataSource }
        set { scrollView.dataSource = newValue }
    }

    weak var delegate: TitleScrollViewDelegate? {
        get { return scrollView.scrollViewDelegate }
        set { scrollView.scrollViewDelegate = newValue }
    }

    var textColor: UIColor! {
        get { return scrollView.textColor }
        set { scrollView.textColor = newValue }
    }

    var items: [UIView] { return scrollView.items }

    var visibleItem: UIView? {
        get { return scrollView.visibleItem }
        set { scrollView.visibleItem = newValue }
    }

    var accessibilityHint: String? {
        get { return scrollView.accessibilityHint }
        set { scrollView.accessibilityHint = newValue }
    }

    var accessibilityLabel: String? {
        get { return scrollView.accessibilityLabel }
        set { scrollView.accessibilityLabel = newValue }
    }

    func refreshItems() {
        scrollView.refreshItems()
    }

    func updateVisibleItem() {
        scrollView.updateVisibleItem()
    }

}

// MARK: - Main

class TitleScrollView: UIScrollView, UIScrollViewDelegate {

    var fontSize = Appearance.primaryTextFontSize

    weak var scrollViewDelegate: TitleScrollViewDelegate?

    weak var dataSource: TitleScrollViewDataSource? {
        didSet {
            guard let _ = dataSource else { return }
            refreshItems()
        }
    }

    var textColor: UIColor! {
        didSet {
            updateTextAppearance()
        }
    }

    var items: [UIView] { return stackView.arrangedSubviews }

    var visibleItem: UIView? {
        didSet {
            guard let visibleItem = visibleItem, visibleItem != oldValue else { return }
            if shouldAnimateChanges {
                layoutIfNeeded()
                var offset = visibleItem.frame.origin
                switch scrollOrientation {
                case .horizontal: offset.y = contentOffset.y
                case .vertical: offset.x = contentOffset.x
                }
                setContentOffset(offset, animated: true)
            }
            if let _ = oldValue, let delegate = scrollViewDelegate {
                delegate.titleScrollView(self, didChangeVisibleItem: visibleItem)
            }
        }
    }
    var shouldAnimateChanges = false

    var scrollOrientation: ScrollOrientation = .vertical {
        didSet {
            switch scrollOrientation {
            case .horizontal: stackView.axis = .horizontal
            case .vertical: stackView.axis = .vertical
            }
        }
    }

    fileprivate var stackView: UIStackView!

    override var isPagingEnabled: Bool {
        didSet {
            clipsToBounds = !isPagingEnabled
            isScrollEnabled = isPagingEnabled
            scrollOrientation = isPagingEnabled ? .horizontal : .vertical
            shouldAnimateChanges = isPagingEnabled
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

    private func setUp() {
        delegate = self

        canCancelContentTouches = true
        delaysContentTouches = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false

        stackView = UIStackView(frame: bounds)
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        wrap(view: stackView)

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

    func newItem(type: TitleItemType, text: String) -> UIView {
        switch type {
        case .label:
            let label = newLabel()
            label.text = text
            return label
        case .button:
            let button = newButton()
            button.setTitle(text, for: .normal)
            button.addTarget(self, action: #selector(handleTap(forButton:)), for: .touchUpInside)
            return button
        }
    }

    private func newLabel() -> UILabel {
        let label = ExtendedLabel(frame: .zero)
        label.font = UIFont.boldSystemFont(ofSize: fontSize)
        label.textAlignment = .center
        label.textColor = textColor
        label.isAccessibilityElement = true
        return label
    }

    private func newButton() -> UIButton {
        guard isPagingEnabled else { preconditionFailure() }
        let button = UIButton(frame: .zero)
        button.titleLabel!.font = UIFont.boldSystemFont(ofSize: fontSize)
        button.titleLabel!.textAlignment = .center
        button.titleLabel!.textColor = textColor
        return button
    }

    // MARK: - Updating

    func refreshItems() {
        for item in items {
            stackView.removeArrangedSubview(item)
            item.removeFromSuperview()
        }
        let count = dataSource!.titleScrollViewItemCount(self)
        for i in 0..<count {
            let item = dataSource!.titleScrollView(self, itemAt: i)!
            stackView.addArrangedSubview(item)
            NSLayoutConstraint.activate([
                item.heightAnchor.constraint(equalTo: heightAnchor),
                item.widthAnchor.constraint(equalTo: widthAnchor)
            ])
        }
    }

    func updateVisibleItem() {
        guard visibleItem != nil else {
            visibleItem = items[0]
            return
        }
        for item in items where isItemVisible(item) {
            visibleItem = item
            break
        }
    }

    private func isItemVisible(_ item: UIView) -> Bool {
        let frame = item.frame, origin = frame.origin
        let metrics: (offset: CGFloat, start: CGFloat, end: CGFloat)!
        switch scrollOrientation {
        case .horizontal: metrics = (contentOffset.x, origin.x, origin.x + frame.width)
        case .vertical: metrics = (contentOffset.y, origin.y, origin.y + frame.height)
        }
        return metrics.offset >= metrics.start && metrics.offset < metrics.end
    }

    private func updateTextAppearance() {
        for item in items {
            switch item {
            case let (button as UIButton): button.setTitleColor(textColor, for: .normal)
            case let (label as UILabel): label.textColor = textColor
            default: fatalError("Invalid item.")
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

class TitleMaskedScrollView: UIView, TitleScrollViewProxy {

    var maskColor = UIColor.white
    var maskRatio = 0.2
    var fontSize: CGFloat! {
        get { return scrollView.fontSize }
        set { scrollView.fontSize = newValue }
    }

    // MARK: TitleScrollViewProxy

    var scrollView: TitleScrollView!

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView = TitleScrollView(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scrollView = TitleScrollView(coder: aDecoder)!
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
            guard let rawValue = delegate!.titleScrollViewContext?(scrollView),
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
        let maskRatio: Double!
        switch scrollView.scrollOrientation {
        case .horizontal:
            maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
            maskLayer.endPoint = CGPoint(x: 1, y: 0.5)
            maskRatio = self.maskRatio
        case .vertical:
            maskLayer.startPoint = CGPoint(x: 0.5, y: 0)
            maskLayer.endPoint = CGPoint(x: 0.5, y: 1)
            maskRatio = self.maskRatio * 2
        }
        maskLayer.locations = [0, NSNumber(value: maskRatio), NSNumber(value: 1 - maskRatio), 1]
        layer.mask = maskLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.mask?.frame = bounds
    }

}

// MARK: - Control

class TitlePickerView: UIControl, TitleScrollViewProxy {

    fileprivate var maskedScrollView: TitleMaskedScrollView!

    // MARK: TitleScrollViewProxy

    var scrollView: TitleScrollView! { return maskedScrollView.scrollView }

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        maskedScrollView = TitleMaskedScrollView(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        maskedScrollView = TitleMaskedScrollView(coder: aDecoder)
    }

    func setUp() {
        maskedScrollView.fontSize = 16 // TODO: Temporary.
        wrap(view: maskedScrollView)

        scrollView.isPagingEnabled = true
        maskedScrollView.setUp()
    }

    // MARK: - UIControl

    override var isEnabled: Bool {
        didSet {
            scrollView.clipsToBounds = !isEnabled
        }
    }

    // MARK: - UIView

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isEnabled else { return nil }
        // Work around UIScrollView width (and hitbox) being tied to page-size when pagingEnabled.
        guard point.x >= 0 && point.x <= bounds.width else { return nil }

        let scrollViewPoint = convert(point, to: scrollView)
        var descendantView = scrollView.hitTest(scrollViewPoint, with: event)
        descendantView = descendantView ?? scrollView
        return descendantView
    }

}
