//
//  CollectionViewDataLoadingTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@objc protocol CollectionViewDataLoadingTraitDelegate: NSObjectProtocol {

    var collectionView: UICollectionView? { get }

    @objc optional func handleRefresh()

}

class CollectionViewDataLoadingTrait {

    private(set) weak var delegate: CollectionViewDataLoadingTraitDelegate!

    private var collectionView: UICollectionView! { return delegate.collectionView! }

    private var indicatorView: UIActivityIndicatorView!

    init(delegate: CollectionViewDataLoadingTraitDelegate) {
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

        let refreshSelector = #selector(CollectionViewDataLoadingTraitDelegate.handleRefresh)
        if #available(iOS 10.0, *), delegate.responds(to: refreshSelector) {
            let refreshControl = UIRefreshControl(frame: .zero)
            refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
            refreshControl.tintColor = containerView.tintColor
            collectionView.refreshControl = refreshControl
        }
    }

    @objc private func handleRefresh(_ sender: UIRefreshControl) {
        delegate.handleRefresh?()
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
    }

}
