//
//  DeletionDropzoneView.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

final class DeletionDropzoneView: UICollectionReusableView {

    @IBOutlet private(set) var mainLabel: TitleMaskedScrollView!
    @IBOutlet private(set) var innerContentView: UIView!
    @IBOutlet private(set) var heightConstraint: NSLayoutConstraint!

    fileprivate enum Item {
        case icon, text

        var index: Int {
            switch self {
            case .icon: return 0
            case .text: return 1
            }
        }

        static func from(index: Int) -> Item {
            switch index {
            case Item.icon.index: return .icon
            case Item.text.index: return .text
            default: fatalError()
            }
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
        heightConstraint.isActive = true
        setUpBorders()
        setUpMainLabel()
        updateTintColorBasedAppearance()
    }

    private func setUpBorders() {
        clipsToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: -CollectionViewTileCell.borderSize)
        layer.shadowOpacity = 1
        layer.shadowRadius = 0
    }

    private func setUpMainLabel() {
        mainLabel.delegate = self
        mainLabel.scrollView.shouldAnimateChanges = true
        mainLabel.setUp()
        mainLabel.dataSource = self
    }

    private func updateTintColorBasedAppearance() {
        layer.shadowColor = tintColor.cgColor
        mainLabel.textColor = tintColor
    }

    // MARK: - UICollectionReusableView

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {

        guard let layoutAttributes = layoutAttributes as? DeletionDropzoneAttributes
            else { preconditionFailure() }
        let items = mainLabel.items
        mainLabel.visibleItem = (
            layoutAttributes.isTextVisible ? items[Item.text.index] : items[Item.icon.index]
        )
        super.apply(layoutAttributes)
    }

    // MARK: - UIView

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateTintColorBasedAppearance()
    }

}

extension DeletionDropzoneView: TitleScrollViewDataSource {

    func titleScrollViewItemCount(_ scrollView: TitleScrollView) -> Int {
        return 2
    }

    func titleScrollView(_ scrollView: TitleScrollView, itemAt index: Int) -> UIView? {
        switch Item.from(index: index) {
        case .icon:
            guard let iconLabel = scrollView.newItem(type: .label, text: "") as? UILabel
                else { preconditionFailure() }
            iconLabel.icon = .trash
            return iconLabel
        case .text:
            guard let textLabel = scrollView.newItem(type: .label, text: "Delete?") as? UILabel
                else { preconditionFailure() }
            textLabel.font = UIFont.systemFont(
                ofSize: Appearance.primaryTextFontSize, weight: UIFontWeightRegular
            )
            return textLabel
        }
    }

}

extension DeletionDropzoneView: TitleScrollViewDelegate {

    func titleScrollView(_ scrollView: TitleScrollView, didChangeVisibleItem visibleItem: UIView) {}

    func titleScrollView(_ scrollView: TitleScrollView,
                         offsetForItem item: UIView, at index: Int) -> UIOffset {
        switch Item.from(index: index) {
        case .icon: return UIOffset(horizontal: 0, vertical: 0) // See ExtendedLabel.drawText(in:).
        case .text: return UIOffset(horizontal: 4, vertical: 0)
        }
    }

}
