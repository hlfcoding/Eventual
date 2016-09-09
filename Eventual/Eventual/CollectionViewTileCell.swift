//
//  CollectionViewTileCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

// FIXME: Currently crashes if @IBDesignable is added.
class CollectionViewTileCell: UICollectionViewCell {

    // MARK: - State

    var isDetached = false {
        didSet {
            innerContentView.backgroundColor = isDetached ?
                Appearance.collectionViewBackgroundColor : originalBackgroundColor
            toggleContentAppearance(!isDetached)
        }
    }
    private var originalBackgroundColor: UIColor?

    // MARK: - Border Aspect

    @IBOutlet private(set) var innerContentView: UIView!

    @IBOutlet private(set) var borderTopConstraint: NSLayoutConstraint!
    @IBOutlet private(set) var borderLeftConstraint: NSLayoutConstraint!
    @IBOutlet private(set) var borderBottomConstraint: NSLayoutConstraint!
    @IBOutlet private(set) var borderRightConstraint: NSLayoutConstraint!

    var borderColor: UIColor! { return backgroundColor }
    var borderSize: CGFloat!
    /**
     This is a computed property over the border constraints, which is an implementation of partial
     borders.
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
            borderTopConstraint.constant = newValue.top
            borderLeftConstraint.constant = newValue.left
            borderBottomConstraint.constant = newValue.bottom
            borderRightConstraint.constant = newValue.right
        }
    }
    var borderSizesWithScreenEdges: UIEdgeInsets?
    var originalBorderSizes: UIEdgeInsets?
    var originalFrame: CGRect?

    func restoreOriginalBordersIfNeeded() -> Bool {
        if let original = originalFrame { // TODO: Temp.
            frame = original
            originalFrame = nil
        }
        guard let original = originalBorderSizes where original != borderSizes else { return false }
        return setBorderSizesIfNeeded(original)
    }

    /**
     `layoutIfNeeded` gets called on set for now to avoid disappearing borders during transitioning.
     A couple unneeded layouts of cell subviews may occur, and that cost seems okay.
     */
    func setBorderSizesIfNeeded(newValue: UIEdgeInsets) -> Bool {
        guard newValue != borderSizes else { return false }
        borderSizes = newValue
        layoutIfNeeded()
        return true
    }

    func toggleAllBorders(visible: Bool) {
        let size = visible ? borderSize : 0
        setBorderSizesIfNeeded(UIEdgeInsets(top: size, left: size, bottom: size, right: size))
    }

    func maintainInnerContentScale() {
        guard let original = originalBorderSizes else { return }
        originalFrame = frame
        let diff = (
            bottom: borderSizes.bottom - original.bottom,
            left: borderSizes.left - original.left,
            right: borderSizes.right - original.right,
            top: borderSizes.top - original.top
        )
        frame.size.height += diff.bottom + diff.top
        frame.size.width += diff.left + diff.right
    }

    func showBordersWithScreenEdgesIfNeeded() -> Bool {
        guard let borderSizes = borderSizesWithScreenEdges else { return false }
        return setBorderSizesIfNeeded(borderSizes)
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
        if changedConstraints {
            setNeedsUpdateConstraints()
        }

        UIView.animateWithDuration(highlightDuration) {
            self.innerContentView.transform = transform
            if changedConstraints {
                self.layoutIfNeeded()
            }
        }
    }

    func animateUnhighlighted(completion: (() -> Void)? = nil) {
        let changedConstraints = restoreOriginalBordersIfNeeded()
        if changedConstraints {
            setNeedsUpdateConstraints()
        }

        UIView.animateWithDuration(highlightDuration, animations: {
            self.innerContentView.transform = CGAffineTransformIdentity
            if changedConstraints {
                self.layoutIfNeeded()
            }
        }) { finished in
            completion?()
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
        isAccessibilityElement = true
        originalBackgroundColor = innerContentView.backgroundColor
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
        isDetached = false
    }

    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        if let tileLayoutAttributes = layoutAttributes as? CollectionViewTileLayoutAttributes {
            borderSize = tileLayoutAttributes.borderSize
            borderSizes = tileLayoutAttributes.borderSizes
            borderSizesWithScreenEdges = tileLayoutAttributes.borderSizesWithScreenEdges
            originalBorderSizes = borderSizes
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
