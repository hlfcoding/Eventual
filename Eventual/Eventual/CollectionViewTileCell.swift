//
//  CollectionViewTileCell.swift
//  Eventual
//
//  Created by Peng Wang on 10/25/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETCollectionViewTileCell) class CollectionViewTileCell: UICollectionViewCell {

    // MARK: - Border Aspect

    @IBOutlet var innerContentView: UIView!
    
    @IBOutlet private var borderTopConstraint: NSLayoutConstraint!
    @IBOutlet private var borderLeftConstraint: NSLayoutConstraint!
    @IBOutlet private var borderBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var borderRightConstraint: NSLayoutConstraint!
    
    var borderInsets: UIEdgeInsets! {
        didSet {
            self.borderTopConstraint.constant = self.borderInsets.top
            self.borderLeftConstraint.constant = self.borderInsets.left
            self.borderBottomConstraint.constant = self.borderInsets.bottom
            self.borderRightConstraint.constant = self.borderInsets.right
        }
    }
    var defaultBorderInsets: UIEdgeInsets!
    
    var depressDamping: CGFloat = 0.7
    var depressDuration: NSTimeInterval = 0.4
    var depressOptions: UIViewAnimationOptions = .CurveEaseInOut | .BeginFromCurrentState
    var depressScale: CGFloat = 0.98
    
    override var highlighted: Bool {
        didSet {
            if !self.highlighted { return }
            let transform = CGAffineTransformMakeScale(self.depressScale, self.depressScale)
            self.innerContentView.transform = transform
            UIView.animateWithDuration( self.depressDuration, delay: 0.0,
                usingSpringWithDamping: self.depressDamping, initialSpringVelocity: 0.0,
                options: self.depressOptions,
                animations: { self.innerContentView.transform = CGAffineTransformIdentity },
                completion: nil
            )
        }
    }

    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setUp()
    }

    func setUp() {
        self.borderInsets = UIEdgeInsets(
            top: self.borderTopConstraint.constant, left: self.borderLeftConstraint.constant,
            bottom: self.borderBottomConstraint.constant, right: self.borderRightConstraint.constant
        )
        self.defaultBorderInsets = self.borderInsets
        self.updateTintColorBasedAppearance()
    }
    
    // MARK: - UICollectionReusableView

    override func prepareForReuse() {
        super.prepareForReuse()
        self.innerContentView.layer.removeAllAnimations()
        self.innerContentView.transform = CGAffineTransformIdentity
    }

    // MARK: - UIView

    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.updateTintColorBasedAppearance()
    }
    
    func updateTintColorBasedAppearance() {
        self.backgroundColor = self.tintColor
    }

}