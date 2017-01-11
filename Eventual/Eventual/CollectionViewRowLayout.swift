//
//  CollectionViewRowLayout.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class CollectionViewRowLayout: UICollectionViewFlowLayout {

    private var fluidity: CollectionViewFlowLayoutFluidity!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        let layoutInfo = CollectionViewFlowLayoutFluidity.LayoutInfo(
            desiredItemSize: itemSize,
            minimumInteritemSpacing: CGSize(width: minimumInteritemSpacing, height: minimumLineSpacing),
            sectionInset: sectionInset,
            viewportSize: viewportSize
        )
        fluidity = CollectionViewFlowLayoutFluidity(layoutInfo: layoutInfo)
    }

    func viewportSize() -> CGSize {
        return collectionView!.bounds.size
    }

    override func prepare() {
        super.prepare()

        fluidity.staticNumberOfColumns = 1
        estimatedItemSize = fluidity.itemSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard var attributesCollection = super.layoutAttributesForElements(in: rect) else { return nil }
        for (index, attributes) in attributesCollection.enumerated() where attributes.representedElementCategory == .cell {
            attributesCollection[index] = layoutAttributesForItem(at: attributes.indexPath)!
        }
        return attributesCollection
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        attributes?.bounds.size.width = viewportSize().width
        return attributes
    }

}
