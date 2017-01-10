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
        itemSize = fluidity.itemSize
    }

}
