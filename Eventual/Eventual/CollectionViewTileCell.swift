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

    var borderColor: UIColor! { return self.backgroundColor }
    var borderSize: CGFloat!
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
    var borderSizesWithScreenEdges: UIEdgeInsets?
    private var originalBorderSizes: UIEdgeInsets?

    func restoreOriginalBordersIfNeeded() -> Bool {
        guard let original = self.originalBorderSizes
              else { assertionFailure("Nothing to restore to."); return false }
        guard original != self.borderSizes else { return false }
        self.borderSizes = original
        return true
    }

    func toggleAllBorders(visible: Bool) {
        self.originalBorderSizes = self.originalBorderSizes ?? self.borderSizes
        let size = visible ? self.borderSize : 0.0
        self.borderSizes = UIEdgeInsets(top: size, left: size, bottom: size, right: size)
    }

    func showBordersWithScreenEdgesIfNeeded() -> Bool {
        guard let borderSizes = self.borderSizesWithScreenEdges else { return false }
        self.originalBorderSizes = self.borderSizes
        self.borderSizes = borderSizes
        return true
    }

    func addBordersToSnapshotView(snapshot: UIView) {
        snapshot.layer.borderWidth = self.borderSize
        snapshot.layer.borderColor = self.borderColor.CGColor
    }

    // MARK: - Highlight Aspect

    @IBInspectable var highlightDuration: Double = 0.1 // FIXME: Revert to NSTimeInterval when IBInspectable supports it.
    @IBInspectable var highlightDepressDepth: CGFloat = 3.0

    func animateHighlighted() {
        // Use aspect ratio to inversely affect depth scale.
        // The larger the dimension, the smaller the relative scale.
        let relativeDepressDepth = UIOffset(
            horizontal: self.highlightDepressDepth / self.frame.width,
            vertical: self.highlightDepressDepth / self.frame.height
        )
        let transform = CGAffineTransformMakeScale(
            1.0 - relativeDepressDepth.horizontal,
            1.0 - relativeDepressDepth.vertical
        )

        // Keep borders equal for symmetry.
        let changedConstraints = self.showBordersWithScreenEdgesIfNeeded()
        if changedConstraints { self.setNeedsUpdateConstraints() }

        UIView.animateWithDuration( self.highlightDuration,
            delay: 0.0, options: [.BeginFromCurrentState],
            animations: {
                self.innerContentView.transform = transform
                if changedConstraints { self.layoutIfNeeded() }
            }, completion: nil
        )
    }

    func animateUnhighlighted() {
        let changedConstraints = self.restoreOriginalBordersIfNeeded()
        if changedConstraints { self.setNeedsUpdateConstraints() }

        UIView.animateWithDuration( self.highlightDuration,
            delay: 0.0, options: [.BeginFromCurrentState],
            animations: {
                self.innerContentView.transform = CGAffineTransformIdentity
                if changedConstraints { self.layoutIfNeeded() }
            }, completion: nil
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

    // MARK: - Helpers

    func toggleContentAppearance(visible: Bool) {
        let alpha: CGFloat = visible ? 1.0 : 0.0
        for view in self.innerContentView.subviews {
            view.alpha = alpha
        }
    }

    // MARK: - UICollectionReusableView

    override func prepareForReuse() {
        super.prepareForReuse()
        self.innerContentView.layer.removeAllAnimations()
        self.innerContentView.transform = CGAffineTransformIdentity
    }

    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        if let tileLayoutAttributes = layoutAttributes as? CollectionViewTileLayoutAttributes {
            self.borderSize = tileLayoutAttributes.borderSize
            self.borderSizes = tileLayoutAttributes.borderSizes
            self.borderSizesWithScreenEdges = tileLayoutAttributes.borderSizesWithScreenEdges
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