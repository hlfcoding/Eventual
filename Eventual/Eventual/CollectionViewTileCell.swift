//
//  CollectionViewTileCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

// FIXME: Currently crashes if @IBDesignable is added.
class CollectionViewTileCell: UICollectionViewCell {

    static let borderSize: CGFloat = 1

    // MARK: - State

    var isDetached = false {
        didSet {
            innerContentView.backgroundColor = isDetached ?
                Appearance.collectionViewBackgroundColor : originalBackgroundColor
            layer.shadowOpacity = isDetached ? 0 : 1
            toggleContentAppearance(!isDetached)
            setNeedsDisplay()
        }
    }
    private var originalBackgroundColor: UIColor?

    // MARK: - Highlight Aspect

    @IBOutlet private(set) var innerContentView: UIView!

    @IBInspectable var highlightDuration: Double = 0.05 // FIXME: Revert to NSTimeInterval when IBInspectable supports it.
    @IBInspectable var highlightDepressDepth: CGFloat = 8

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
        UIView.animateWithDuration(highlightDuration) {
            self.innerContentView.transform = transform
        }
    }

    func animateUnhighlighted(completion: (() -> Void)? = nil) {
        UIView.animateWithDuration(highlightDuration, animations: {
            self.innerContentView.transform = CGAffineTransformIdentity
        }) { finished in
            completion?()
        }
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        preconditionFailure("Can only be initialized from nib.")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        isAccessibilityElement = true
        originalBackgroundColor = innerContentView.backgroundColor
        setUpBorders()
        updateTintColorBasedAppearance()
    }

    // MARK: - Helpers

    var staticContentSubviews: [UIView] { return innerContentView.subviews }

    func setUpBorders() {
        clipsToBounds = false
        layer.shadowOffset = CGSizeZero
        layer.shadowOpacity = 1
        layer.shadowRadius = 0
    }

    func updateTintColorBasedAppearance() {
        layer.shadowColor = tintColor.CGColor
    }

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
        let borderSize = CollectionViewTileCell.borderSize
        layer.shadowPath = UIBezierPath(rect: layoutAttributes.bounds.insetBy(dx: -borderSize, dy: -borderSize)).CGPath
        super.applyLayoutAttributes(layoutAttributes)
    }

    // MARK: - UIView

    override func snapshotViewAfterScreenUpdates(afterUpdates: Bool) -> UIView? {
        let borderSize = CollectionViewTileCell.borderSize
        let view = super.snapshotViewAfterScreenUpdates(afterUpdates)
        view!.frame.insetInPlace(dx: -borderSize, dy: -borderSize)
        view!.layer.borderColor = layer.shadowColor
        view!.layer.borderWidth = borderSize
        return view
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateTintColorBasedAppearance()
    }

}
