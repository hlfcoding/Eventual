//
//  NavigationTitleScrollView.swift
//  Eventual
//
//  Created by Peng Wang on 8/1/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit
import QuartzCore

enum ETNavigationItemType {
    case Label, Button
}

@objc(ETNavigationTitleScrollView) class NavigationTitleScrollView : UIScrollView,
    NavigationTitleViewProtocol, UIScrollViewDelegate
{
    
    var textColor: UIColor! {
    didSet {
        dispatch_async(dispatch_get_main_queue()) {
            self.updateTextAppearance()
        }
    }
    }
    
    var visibleItem: UIView? {
    didSet {
        if self.visibleItem == oldValue { return }
        if let visibleItem = self.visibleItem {
            self.setContentOffset(
                CGPoint(x: visibleItem.frame.origin.x, y: self.contentOffset.y),
                animated: true
            )
        }
    }
    }
    
    private var shouldLayoutMasks = false
    
    init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    init(coder aDecoder: NSCoder!) {
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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.shouldLayoutMasks {
            for subview in self.subviews as [UIView] {
                let maskLayer = subview.layer.mask as CAGradientLayer
                if CGSizeEqualToSize(maskLayer.frame.size, subview.bounds.size) {
                    self.shouldLayoutMasks = false
                    break
                }
                maskLayer.frame = subview.bounds
            }
        }
    }
    
    func addItemOfType(type: ETNavigationItemType, withText text: String) -> UIView {
        self.shouldLayoutMasks = true
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
        self.updateContentSizeForSubview(subview)
        return subview
    }
    
    func processItems() {
        self.updateVisibleItem()
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
        button.titleLabel.font = UIFont.boldSystemFontOfSize(button.titleLabel.font.pointSize)
        button.titleLabel.textAlignment = .Center
        self.setUpSubview(button)
        return button
    }

    private func setUpSubview(subview: UIView) {
        // TODO: Long.
    }
    
    private func updateContentSizeForSubview(subview: UIView) {
        self.contentSize = CGSize(
            width: self.contentSize.width + self.frame.size.width,
            height: self.contentSize.height
        )
    }

    private func updateTextAppearance() {
        // TODO: Long.
    }

    private func updateVisibleItem() {
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
    
    // MARK: UIScrollViewDelegate
    
    private let throttleThresholdOffset: CGFloat = 1.0
    private var previousOffset: CGFloat = -1.0
    
    func scrollViewDidScroll(scrollView: UIScrollView!) {
        let offset = self.contentOffset.x
        if self.previousOffset == -1.0 {
            self.previousOffset = offset
        } else if abs(offset - self.previousOffset) < self.throttleThresholdOffset {
            return
        } else {
            self.previousOffset = offset
            self.updateTextAppearance()
        }
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView!) {
        self.updateVisibleItem()
    }
    
}