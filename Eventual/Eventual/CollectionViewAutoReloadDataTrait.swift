//
//  CollectionViewAutoReloadDataTrait.swift
//  Eventual
//
//  Created by Peng Wang on 1/18/16.
//  Copyright (c) 2016 Eventual App. All rights reserved.
//

import UIKit
import EventKit

class CollectionViewAutoReloadDataTrait {

    private(set) var collectionView: UICollectionView!

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    dynamic func reloadFromEntityOperationNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
            // FIXME: This is pretty ugly, due to being forced to store raw value inside dict.
            type = userInfo[TypeKey] as? UInt where type == EKEntityType.Event.rawValue
            else { return }
        self.collectionView.reloadData()
    }

}