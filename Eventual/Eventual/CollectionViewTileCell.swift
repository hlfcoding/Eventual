//
//  CollectionViewTileCell.swift
//  Eventual
//
//  Created by Peng Wang on 10/25/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit

// FIXME: Currently crashes if @IBDesignable is added.
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

    @IBInspectable var highlightDuration: Double = 0.1 // FIXME: Revert to NSTimeInterval when IBInspectable supports it.
    @IBInspectable var highlightDepressDepth: CGFloat = 3.0

    func animateHighlighted() {
        // Use aspect ratio to inversely affect depth scale.
        // The larger the dimension, the smaller the relative scale.
        let relativeDepressDepth = UIOffset(
            horizontal: self.highlightDepressDepth / self.frame.size.width,
            vertical: self.highlightDepressDepth / self.frame.size.height
        )
        let transform = CGAffineTransformMakeScale(
            1.0 - relativeDepressDepth.horizontal,
            1.0 - relativeDepressDepth.vertical
        )
        UIView.animateWithDuration( self.highlightDuration,
            delay: 0.0, options: [.BeginFromCurrentState],
            animations: { self.innerContentView.transform = transform }, completion: nil
        )
    }

    func animateUnhighlighted() {
        UIView.animateWithDuration( self.highlightDuration,
            delay: 0.0, options: [.BeginFromCurrentState],
            animations: { self.innerContentView.transform = CGAffineTransformIdentity }, completion: nil
        )
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    required init?(coder aDecoder: NSCoder) {
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

    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
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