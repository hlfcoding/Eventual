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
    
    // MARK: Private
    
    private var shouldLayoutMasks = false
    
    private let whiteColor = UIColor.whiteColor().CGColor
    private let clearColor = UIColor.clearColor().CGColor
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    required init(coder aDecoder: NSCoder!) {
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
        let maskLayer = CAGradientLayer()
        maskLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        maskLayer.masksToBounds = true
        maskLayer.colors = [ self.whiteColor, self.whiteColor ] as NSArray
        maskLayer.locations = [ 0.0, 1.0 ]
        subview.layer.mask = maskLayer
    }
    
    // MARK: - Updating

    func processItems() {
        self.updateVisibleItem()
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
    
    private func updateContentSizeForSubview(subview: UIView) {
        self.contentSize = CGSize(
            width: self.contentSize.width + self.frame.size.width,
            height: self.contentSize.height
        )
    }

    private func updateTextAppearance() {
        let colorScalar: CGFloat = 0.5
        let maskScalar: CGFloat = 2.5
        let offsetThreshold: CGFloat = 95.0
        let siblingThreshold: CGFloat = offsetThreshold / 2.0
        let priorMaskColors = [ self.clearColor, self.whiteColor ]
        let subsequentMaskColors = [ self.whiteColor, self.clearColor ]
        let currentMaskColorsAndLocations = [ [ self.whiteColor, self.whiteColor ], [ 0.0, 1.0 ] ]
        let rgb = CGColorGetComponents(self.textColor.CGColor)
        let contentOffset = self.contentOffset.x
        for subview in self.subviews as [UIView] {
            let frame = subview.frame
            let offset = frame.origin.x - contentOffset
            let isPriorSibling = offset < -siblingThreshold
            let isSubsequentSibling = offset > siblingThreshold
            let colorRatio = CGFloat(colorScalar * min(abs(offset) / frame.size.width, 1.0))
            // Update color.
            let color = UIColor(red: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1.0 - colorRatio)
            if let button = subview as? UIButton {
                button.setTitleColor(color, forState: .Normal)
            } else if let label = subview as? UILabel {
                label.textColor = color
            }
            // Update Mask.
            let maskLayer = subview.layer.mask as CAGradientLayer
            let maskRatio = maskScalar * CGFloat(min((abs(offset) - offsetThreshold) / frame.size.width, 1.0))
            if isPriorSibling {
                maskLayer.colors = priorMaskColors
                maskLayer.locations = [ maskRatio, 1.0 ]
            } else if isSubsequentSibling {
                maskLayer.colors = subsequentMaskColors
                maskLayer.locations = [ 0.0, 1.0 - maskRatio ]
            } else {
                maskLayer.colors = currentMaskColorsAndLocations.firstObject as [UIColor]
                maskLayer.locations = currentMaskColorsAndLocations.lastObject as [NSNumber]
            }
        }
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
    
    // MARK: - UIScrollViewDelegate
    
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