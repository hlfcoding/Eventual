//
//  CollectionViewDataLoadingTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

class CollectionViewDataLoadingTrait {

    private(set) weak var delegate: CollectionViewTraitDelegate!

    private var collectionView: UICollectionView! { return delegate.collectionView! }

    private var indicatorView: UIActivityIndicatorView!

    var needsReload = false

    init(delegate: CollectionViewTraitDelegate) {
        self.delegate = delegate

        let containerView = collectionView.superview!
        indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        indicatorView.color = containerView.tintColor
        indicatorView.hidesWhenStopped = true
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(indicatorView)
        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
        indicatorView.startAnimating()

        if #available(iOS 10.0, *) {
            let refreshControl = UIRefreshControl(frame: .zero)
            refreshControl.addTarget(nil, action: Selector(("handleRefresh:")), for: .valueChanged)
            refreshControl.tintColor = containerView.tintColor
            collectionView.refreshControl = refreshControl
        }
    }

    func dataDidLoad() {
        if indicatorView.isAnimating {
            indicatorView.stopAnimating()
        }
        if #available(iOS 10.0, *) {
            if let refreshControl = collectionView!.refreshControl, refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
        }
        needsReload = true
        guard !collectionView.isDragging && !collectionView.isDecelerating else { return }
        reloadIfNeeded()
    }

    func reloadIfNeeded() {
        guard needsReload else { return }
        collectionView.reloadData()
        needsReload = false
    }

}
