//
//  CollectionViewTileCell.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class CollectionViewTileCell: UICollectionViewCell {

    static let borderSize: CGFloat = 1

    // MARK: - State

    var isDetached = false {
        didSet {
            innerContentView.backgroundColor = isDetached ?
                Appearance.collectionViewBackgroundColor : originalBackgroundColor
            layer.shadowOpacity = isDetached ? 0 : 1
            toggleContent(visible: !isDetached)
            setNeedsDisplay()
        }
    }
    private var originalBackgroundColor: UIColor?

    // MARK: - Highlight Aspect

    @IBOutlet private(set) var innerContentView: UIView!

    @IBInspectable var highlightDuration: Double = 0.05 // FIXME: Revert to NSTimeInterval when IBInspectable supports it.
    @IBInspectable var highlightDepressDepth: CGFloat = 8

    func animateHighlighted(depressDepth customDepressDepth: UIOffset = .zero) {
        let depressDepth: UIOffset!
        if customDepressDepth != .zero {
            depressDepth = customDepressDepth
        } else {
            // Use aspect ratio to inversely affect depth scale.
            // The larger the dimension, the smaller the relative scale.
            depressDepth = UIOffset(
                horizontal: highlightDepressDepth / frame.width,
                vertical: highlightDepressDepth / frame.height
            )
        }
        let transform = CGAffineTransform(
            scaleX: 1 - depressDepth.horizontal,
            y: 1 - depressDepth.vertical
        )
        UIView.animate(withDuration: highlightDuration) {
            self.innerContentView.transform = transform
        }
    }

    func animateUnhighlighted(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: highlightDuration, animations: {
            self.innerContentView.transform = .identity
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
        layer.shadowOffset = .zero
        layer.shadowOpacity = 1
        layer.shadowRadius = 0
    }

    func updateTintColorBasedAppearance() {
        layer.shadowColor = tintColor.cgColor
    }

    func toggleContent(visible: Bool) {
        let alpha: CGFloat = visible ? 1 : 0
        for view in innerContentView.subviews {
            view.alpha = alpha
        }
    }

    // MARK: - UICollectionReusableView

    override func prepareForReuse() {
        super.prepareForReuse()
        innerContentView.layer.removeAllAnimations()
        innerContentView.transform = .identity
        isDetached = false
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        let borderSize = CollectionViewTileCell.borderSize
        layer.shadowPath = UIBezierPath(rect: layoutAttributes.bounds.insetBy(dx: -borderSize, dy: -borderSize)).cgPath
        super.apply(layoutAttributes)
    }

    // MARK: - UIView

    override func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
        let borderSize = CollectionViewTileCell.borderSize
        guard let view = super.snapshotView(afterScreenUpdates: afterUpdates) else { return nil }
        view.frame = view.frame.insetBy(dx: -borderSize, dy: -borderSize)
        view.layer.borderColor = layer.shadowColor
        view.layer.borderWidth = borderSize
        return view
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateTintColorBasedAppearance()
    }

}
