//
//  EventDeletionDropzoneView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

final class EventDeletionDropzoneView: UICollectionReusableView {

    @IBOutlet var mainLabel: UILabel!

    // MARK: - Border Aspect

    @IBOutlet var innerContentView: UIView!
    @IBOutlet var borderTopConstraint: NSLayoutConstraint!
    var borderColor: UIColor! { return backgroundColor }
    var borderSize: CGFloat! {
        didSet {
            borderTopConstraint.constant = borderSize
            guard borderSize != oldValue else { return }
            layoutIfNeeded()
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
        reset()
        updateTintColorBasedAppearance()
    }

    private func reset() {
        mainLabel.icon = .Trash
    }

    // MARK: - UICollectionReusableView

    override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }

    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        if let tileLayoutAttributes = layoutAttributes as? CollectionViewTileLayoutAttributes {
            borderSize = tileLayoutAttributes.borderSize
        }
        super.applyLayoutAttributes(layoutAttributes)
    }

    // MARK: - UIView

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateTintColorBasedAppearance()
    }

    private func updateTintColorBasedAppearance() {
        backgroundColor = tintColor
        mainLabel.textColor = tintColor
    }

}
