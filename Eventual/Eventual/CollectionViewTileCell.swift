//
//  CollectionViewTileCell.swift
//  Eventual
//
//  Created by Peng Wang on 10/25/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

class CollectionViewTileCell: UICollectionViewCell {

    // MARK: - Border Aspect

    @IBOutlet var innerContentView: UIView!
    
    @IBOutlet var borderTopConstraint: NSLayoutConstraint!
    @IBOutlet var borderLeftConstraint: NSLayoutConstraint!
    @IBOutlet var borderBottomConstraint: NSLayoutConstraint!
    @IBOutlet var borderRightConstraint: NSLayoutConstraint!
    
    var borderSizes: UIEdgeInsets {
        get {
            return UIEdgeInsets(
                top: self.borderTopConstraint.constant,
                left: self.borderLeftConstraint.constant,
                bottom: self.borderBottomConstraint.constant,
                right: self.borderRightConstraint.constant
            )
        }
        set(newSizes) {
            self.borderTopConstraint.constant = newSizes.top
            self.borderLeftConstraint.constant = newSizes.left
            self.borderBottomConstraint.constant = newSizes.bottom
            self.borderRightConstraint.constant = newSizes.right
        }
    }
    
    @IBInspectable var depressDamping: CGFloat = 0.7
    @IBInspectable var depressDuration: Double = 0.4 // FIXME: Revert to NSTimeInterval when IBInspectable supports it.
    @IBInspectable var depressOptions: UIViewAnimationOptions = .CurveEaseInOut | .BeginFromCurrentState
    @IBInspectable var depressDepth: CGFloat = 3.0
    
    override var highlighted: Bool {
        didSet {
            if !self.highlighted { return }
            // Use aspect ratio to inversely affect depth scale. 
            // The larger the dimension, the smaller the relative scale.
            let relativeDepressDepth = UIOffset(
                horizontal: depressDepth / self.frame.size.width,
                vertical: depressDepth / self.frame.size.height
            )
            let transform = CGAffineTransformMakeScale(
                1.0 - relativeDepressDepth.horizontal,
                1.0 - relativeDepressDepth.vertical
            )
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
        self.updateTintColorBasedAppearance()
    }
    
    // MARK: - UICollectionReusableView

    override func prepareForReuse() {
        super.prepareForReuse()
        self.innerContentView.layer.removeAllAnimations()
        self.innerContentView.transform = CGAffineTransformIdentity
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes!) {
        if let tileLayoutAttributes = layoutAttributes as? CollectionViewTileLayoutAttributes {
            self.borderSizes = tileLayoutAttributes.borderSizes
        }
        super.applyLayoutAttributes(layoutAttributes)
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