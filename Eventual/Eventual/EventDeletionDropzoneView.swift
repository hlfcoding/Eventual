//
//  EventDeletionDropzoneView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

final class EventDeletionDropzoneView: UICollectionReusableView {

    @IBOutlet private(set) var mainLabel: UILabel!
    @IBOutlet private(set) var innerContentView: UIView!

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
        mainLabel.icon = .Trash
        setUpBorders()
        updateTintColorBasedAppearance()
    }

    private func setUpBorders() {
        clipsToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: -CollectionViewTileCell.borderSize)
        layer.shadowOpacity = 1
        layer.shadowRadius = 0
    }

    private func updateTintColorBasedAppearance() {
        layer.shadowColor = tintColor.CGColor
        mainLabel.textColor = tintColor
    }

    // MARK: - UICollectionReusableView

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    // MARK: - UIView

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateTintColorBasedAppearance()
    }

}
