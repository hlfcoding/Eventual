//
//  CollectionViewTitleScrollSyncTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

@objc protocol CollectionViewTitleScrollSyncTraitDelegate {

    var collectionView: UICollectionView? { get }
    var currentVisibleContentYOffset: CGFloat { get }
    var titleView: NavigationTitleMaskedScrollView! { get }

    func titleScrollSyncTraitLayoutAttributesAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?

}

class CollectionViewTitleScrollSyncTrait {

    private(set) weak var delegate: CollectionViewTitleScrollSyncTraitDelegate!

    private var collectionView: UICollectionView { return delegate.collectionView! }
    private var titleView: NavigationTitleMaskedScrollView { return delegate.titleView }

    private var currentSectionIndex = 0

    enum ScrollDirection {
        case Bottom, Top
    }
    private var currentScrollDirection: ScrollDirection {
        if let previousContentOffset = previousContentOffset
            where collectionView.contentOffset.y < previousContentOffset.y {
            return .Top
        }
        return .Bottom
    }
    private var previousContentOffset: CGPoint?

    init(delegate: CollectionViewTitleScrollSyncTraitDelegate) {
        self.delegate = delegate
    }

    // NOTE: 'header*' refers to section header metrics, while 'title*' refers to navigation
    // bar title metrics. This function will not short unless we're at the edges.
    func syncTitleViewContentOffsetsWithSectionHeader() {
        let currentIndex = currentSectionIndex

        // The three metrics for comparing against the title view.
        let titleHeight = titleView.frame.height
        var titleBottom = delegate.currentVisibleContentYOffset
        // NOTE: It turns out the spacing between the bar and title is about the same size as the
        // title item's top padding, so they cancel each other out (minus spacing, plus padding).
        var titleTop = titleBottom - titleHeight

        // We use this more than once, but also after conditional guards.
        func headerTopForIndexPath(indexPath: NSIndexPath) -> CGFloat? {
            // NOTE: This will get called a lot.
            guard
                let headerLayoutAttributes = delegate.titleScrollSyncTraitLayoutAttributesAtIndexPath(indexPath)
                else { return nil }

            // The top offset is that margin plus the main layout info's offset.
            let headerLabelTop = CGFloat(UIApplication.sharedApplication().statusBarHidden ? 0 : 9)
            return headerLayoutAttributes.frame.origin.y + headerLabelTop
        }

        var newIndex = currentIndex
        // When scrolling to top/bottom, if the header has visually gone past and below/above the
        // title, commit the switch to the previous/next title. If the header hasn't fully passed
        // the title, add the difference to the offset.
        var offsetChange: CGFloat = 0
        // The default title view content offset, for most of the time, is to offset to title for
        // current index.
        var offset: CGFloat = CGFloat(newIndex) * titleHeight

        switch currentScrollDirection {
        case .Top:
            let previousIndex = currentIndex - 1
            guard previousIndex >= 0 else { return }

            if let headerTop = headerTopForIndexPath(NSIndexPath(forItem: 0, inSection: currentIndex)) {
                // If passed, update new index first.
                if headerTop > titleBottom {
                    newIndex = previousIndex
                }

                offsetChange = titleTop - headerTop
                offset = CGFloat(newIndex) * titleHeight

                // If passing.
                if headerTop >= titleTop && abs(offsetChange) <= titleHeight {
                    offset += offsetChange
                }
            }
        case .Bottom:
            let nextIndex = currentIndex + 1
            guard nextIndex < collectionView.numberOfSections() else { return }

            if let headerTop = headerTopForIndexPath(NSIndexPath(forItem: 0, inSection: nextIndex)) {
                // If passed, update new index first.
                if headerTop < titleTop {
                    newIndex = nextIndex
                }

                offsetChange = titleBottom - headerTop
                offset = CGFloat(newIndex) * titleHeight

                // If passing.
                if headerTop <= titleBottom && abs(offsetChange) <= titleHeight {
                    offset += offsetChange
                }
                // print("headerTop: \(headerTop), titleBottom: \(titleBottom), offset: \(offset)")
            }
        }

        titleView.scrollView.setContentOffset(
            CGPoint(x: titleView.scrollView.contentOffset.x, y: offset), animated: false
        )

        // Update state if needed.
        if newIndex != currentSectionIndex {
            // print(currentSectionIndex)
            currentSectionIndex = newIndex
            previousContentOffset = collectionView.contentOffset
            titleView.updateVisibleItem()
        }
        // print("contentOffset: \(collectionView!.contentOffset.y)")
    }

}
