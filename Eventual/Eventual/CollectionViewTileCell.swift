//
//  CollectionViewTileCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
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

    var borderColor: UIColor! { return backgroundColor }
    var borderSize: CGFloat!
    /**
     This is a computed property over the border constraints, which is an implementation of partial
     borders. `layoutIfNeeded` gets called on set for now to avoid disappearing borders during
     transitioning. A couple unneeded layouts of cell subviews may occur, and that cost seems okay.
     */
    var borderSizes: UIEdgeInsets {
        get {
            return UIEdgeInsets(
                top: borderTopConstraint.constant,
                left: borderLeftConstraint.constant,
                bottom: borderBottomConstraint.constant,
                right: borderRightConstraint.constant
            )
        }
        set(newValue) {
            let oldValue = borderSizes

            borderTopConstraint.constant = newValue.top
            borderLeftConstraint.constant = newValue.left
            borderBottomConstraint.constant = newValue.bottom
            borderRightConstraint.constant = newValue.right

            guard newValue != oldValue else { return }
            layoutIfNeeded()
        }
    }
    var borderSizesWithScreenEdges: UIEdgeInsets?
    private var originalBorderSizes: UIEdgeInsets?

    func restoreOriginalBordersIfNeeded() -> Bool {
        guard let original = originalBorderSizes else { return false }
        guard original != borderSizes else { return false }
        borderSizes = original
        return true
    }

    func toggleAllBorders(visible: Bool) {
        originalBorderSizes = originalBorderSizes ?? borderSizes
        let size = visible ? borderSize : 0
        borderSizes = UIEdgeInsets(top: size, left: size, bottom: size, right: size)
    }

    func showBordersWithScreenEdgesIfNeeded() -> Bool {
        guard let borderSizes = borderSizesWithScreenEdges else { return false }
        originalBorderSizes = self.borderSizes
        self.borderSizes = borderSizes
        return true
    }

    func addBordersToSnapshotView(snapshot: UIView) {
        snapshot.layer.borderWidth = borderSize
        snapshot.layer.borderColor = borderColor.CGColor
    }

    // MARK: - Highlight Aspect

    @IBInspectable var highlightDuration: Double = 0.05 // FIXME: Revert to NSTimeInterval when IBInspectable supports it.
    @IBInspectable var highlightDepressDepth: CGFloat = 3

    func animateHighlighted(depressDepth customDepressDepth: UIOffset = UIOffsetZero) {
        let depressDepth: UIOffset!
        if customDepressDepth != UIOffsetZero {
            depressDepth = customDepressDepth
        } else {
            // Use aspect ratio to inversely affect depth scale.
            // The larger the dimension, the smaller the relative scale.
            depressDepth = UIOffset(
                horizontal: highlightDepressDepth / frame.width,
                vertical: highlightDepressDepth / frame.height
            )
        }
        let transform = CGAffineTransformMakeScale(
            1 - depressDepth.horizontal,
            1 - depressDepth.vertical
        )

        // Keep borders equal for symmetry.
        let changedConstraints = showBordersWithScreenEdgesIfNeeded()
        if changedConstraints { setNeedsUpdateConstraints() }

        UIView.animateWithDuration(highlightDuration) {
            self.innerContentView.transform = transform
            if changedConstraints { self.layoutIfNeeded() }
        }
    }

    func animateUnhighlighted() {
        let changedConstraints = restoreOriginalBordersIfNeeded()
        if changedConstraints { setNeedsUpdateConstraints() }

        UIView.animateWithDuration(highlightDuration) {
            self.innerContentView.transform = CGAffineTransformIdentity
            if changedConstraints { self.layoutIfNeeded() }
        }
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        preconditionFailure("Can only be initialized from nib.")
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updateTintColorBasedAppearance()
    }

    // MARK: - Helpers

    var staticContentSubviews: [UIView] { return innerContentView.subviews }

    func toggleContentAppearance(visible: Bool) {
        let alpha: CGFloat = visible ? 1 : 0
        for view in innerContentView.subviews {
            view.alpha = alpha
        }
    }

    // MARK: - UICollectionReusableView

    override func prepareForReuse() {
        super.prepareForReuse()
        innerContentView.layer.removeAllAnimations()
        innerContentView.transform = CGAffineTransformIdentity
    }

    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        if let tileLayoutAttributes = layoutAttributes as? CollectionViewTileLayoutAttributes {
            borderSize = tileLayoutAttributes.borderSize
            borderSizes = tileLayoutAttributes.borderSizes
            borderSizesWithScreenEdges = tileLayoutAttributes.borderSizesWithScreenEdges
        }
        if layoutAttributes.zIndex == Int.max {
            innerContentView.alpha = 0.7
            backgroundColor = UIColor.clearColor()
        } else {
            innerContentView.alpha = 1
            backgroundColor = tintColor
        }
        super.applyLayoutAttributes(layoutAttributes)
    }

    // MARK: - UIView

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateTintColorBasedAppearance()
    }

    func updateTintColorBasedAppearance() {
        backgroundColor = tintColor
    }

}