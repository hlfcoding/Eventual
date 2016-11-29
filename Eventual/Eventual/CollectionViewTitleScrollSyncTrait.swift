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
    var titleView: TitleMaskedScrollView! { get }

    func titleScrollSyncTraitLayoutAttributes(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?

}

class CollectionViewTitleScrollSyncTrait {

    var isEnabled = true {
        didSet {
            guard isEnabled != oldValue else { return }
            titleView.scrollView.shouldAnimateChanges = !isEnabled
            if isEnabled {
                currentSectionIndex = 0
                previousContentOffset = nil
            }
        }
    }

    private(set) weak var delegate: CollectionViewTitleScrollSyncTraitDelegate!

    private var collectionView: UICollectionView { return delegate.collectionView! }
    private var titleView: TitleMaskedScrollView { return delegate.titleView }

    private var currentSectionIndex = 0

    enum ScrollDirection {
        case down, up
    }
    private var currentDirection: ScrollDirection {
        if let previousContentOffset = previousContentOffset,
            collectionView.contentOffset.y < previousContentOffset.y {
            return .up
        }
        return .down
    }
    private var previousContentOffset: CGPoint?

    private lazy var backToTopRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(returnBackToTop(_:)))
        return recognizer
    }()

    init(delegate: CollectionViewTitleScrollSyncTraitDelegate) {
        self.delegate = delegate

        // NOTE: Default scroll-to-top cannot be straightforwardly modified to sync with
        // `titleView`. And current scroll-sync does not sync correctly when scrolling to top,
        // since `scrollViewDidScroll(_:)` seems to be throttled and may miss the ending if
        // velocity is too great. A CADisplayLink can work, but since a second scroll-to-top
        // behavior is in-spec, the default UIScrollView one is unneeded.
        collectionView.scrollsToTop = false
        titleView.addGestureRecognizer(backToTopRecognizer)
    }

    // NOTE: `header*` refers to section header metrics, while `title*` refers to navigation
    // bar title metrics. This function will not short unless we're at the edges.
    /** This should be called in `scrollViewDidScroll(_:)`. */
    func syncTitleViewContentOffsetsWithSectionHeader() {
        guard isEnabled else { return }

        let currentIndex = currentSectionIndex

        // The three metrics for comparing against the title view.
        let titleHeight = titleView.frame.height
        var titleBottom = delegate.currentVisibleContentYOffset
        // NOTE: It turns out the spacing between the bar and title is about the same size as the
        // title item's top padding, so they cancel each other out (minus spacing, plus padding).
        var titleTop = titleBottom - titleHeight

        // We use this more than once, but also after conditional guards.
        func headerTop(at indexPath: IndexPath) -> CGFloat? {
            // NOTE: This will get called a lot.
            guard let headerLayoutAttributes = delegate.titleScrollSyncTraitLayoutAttributes(at: indexPath)
                else { return nil }

            // The top offset is that margin plus the main layout info's offset.
            let headerLabelTop = CGFloat(UIApplication.shared.isStatusBarHidden ? 0 : 9)
            return headerLayoutAttributes.frame.origin.y + headerLabelTop
        }

        var newIndex = currentIndex
        // When scrolling to top/bottom, if the header has visually gone past and below/above the
        // title, commit the switch to the previous/next title. If the header hasn't fully passed
        // the title, add the difference to the offset.
        var offsetChange: CGFloat = 0
        // The default title view content offset, for most of the time, is to offset to title for
        // current index.
        var offset = CGFloat(newIndex) * titleHeight

        switch currentDirection {
        case .up:
            let previousIndex = currentIndex - 1
            guard previousIndex >= 0 else { return }

            if let headerTop = headerTop(at: IndexPath(item: 0, section: currentIndex)) {
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
        case .down:
            let nextIndex = currentIndex + 1
            guard nextIndex < collectionView.numberOfSections else { return }

            if let headerTop = headerTop(at: IndexPath(item: 0, section: nextIndex)) {
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


    @objc private func returnBackToTop(_ sender: UITapGestureRecognizer) {
        collectionView.setContentOffset(
            CGPoint(x: 0, y: -collectionView.contentInset.top),
            animated: true
        )
        isEnabled = false
        titleView.visibleItem = titleView.items.first
    }

}
