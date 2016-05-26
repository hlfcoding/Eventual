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
    var borderColor: UIColor! { return self.backgroundColor }
    var borderSize: CGFloat! {
        didSet {
            self.borderTopConstraint.constant = self.borderSize
            guard self.borderSize != oldValue else { return }
            self.layoutIfNeeded()
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
        self.reset()
        self.updateTintColorBasedAppearance()
    }

    private func reset() {
        self.mainLabel.icon = .Trash
    }

    // MARK: - UICollectionReusableView

    override func prepareForReuse() {
        super.prepareForReuse()
        self.reset()
    }

    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        if let tileLayoutAttributes = layoutAttributes as? CollectionViewTileLayoutAttributes {
            self.borderSize = tileLayoutAttributes.borderSize
        }
        super.applyLayoutAttributes(layoutAttributes)
    }

    // MARK: - UIView

    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.updateTintColorBasedAppearance()
    }

    private func updateTintColorBasedAppearance() {
        self.backgroundColor = self.tintColor
        self.mainLabel.textColor = self.tintColor
    }

}
