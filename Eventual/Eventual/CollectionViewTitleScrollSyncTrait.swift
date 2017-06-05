//
//  CollectionViewTitleScrollSyncTrait.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit

protocol CollectionViewTitleScrollSyncTraitDelegate: CollectionViewTraitDelegate {

    var currentVisibleContentYOffset: CGFloat { get }
    var titleView: TitleMaskedScrollView! { get }

    func titleScrollSyncTraitLayoutAttributes(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?

}

final class CollectionViewTitleScrollSyncTrait: NSObject {

    var currentSectionIndex = 0
    var isEnabled = false {
        didSet {
            guard isEnabled != oldValue else { return }
            titleView.scrollView.shouldAnimateChanges = !isEnabled
            if isEnabled {
                displayLink.add(to: .current, forMode: .UITrackingRunLoopMode)
            } else {
                displayLink.remove(from: .current, forMode: .UITrackingRunLoopMode)
            }
        }
    }
    private lazy var displayLink: CADisplayLink =
        CADisplayLink(target: self, selector: #selector(sync(_:)))

    private(set) weak var delegate: CollectionViewTitleScrollSyncTraitDelegate!

    private var collectionView: UICollectionView { return delegate.collectionView! }
    private var titleView: TitleMaskedScrollView { return delegate.titleView }

    private lazy var backToTopRecognizer: UITapGestureRecognizer =
        UITapGestureRecognizer(target: self, action: #selector(returnBackToTop(_:)))

    private var isPassing = false
    private var previousDirection: ScrollDirectionY = .down

    init(delegate: CollectionViewTitleScrollSyncTraitDelegate) {
        super.init()
        self.delegate = delegate

        // NOTE: Default scroll-to-top cannot be straightforwardly modified to sync with
        // `titleView`. And current scroll-sync does not sync correctly when scrolling to top,
        // since `scrollViewDidScroll(_:)` seems to be throttled and may miss the ending if
        // velocity is too great. A CADisplayLink can work, but since a second scroll-to-top
        // behavior is in-spec, the default UIScrollView one is unneeded.
        collectionView.scrollsToTop = false
        titleView.addGestureRecognizer(backToTopRecognizer)
    }

    deinit {
        displayLink.invalidate()
    }

    /**
     ```
        Up: -offset      +--------------+-> Content Top +
            -header      |              |               +--> Content Offset
                         |              |               |
               +         +----------------> Frame Top +-+
          pan  |  down   |              |
               v         +----------------> Title Top
                         |              |
                         |              |
                         +----------------> Title Bottom
                         |              |
               ^         +----------------> Header Top
          pan  |  up     ||            ||
               +         ||            ||
                         +--------------+
        Down: +offset    |              |
              +header    +--------------+
     ```
     */
    @objc private func sync(_ sender: CADisplayLink) {
        guard collectionView.contentOffset.y >= 0,
            collectionView.contentOffset.y != collectionView.previousContentOffset?.y
            else { return }

        let titleHeight = titleView.frame.height
        let currentIndex = currentSectionIndex
        var newIndex = currentIndex
        // The default title view content offset, for most of the time, is to offset to title for
        // current index.
        var offset = CGFloat(newIndex) * titleHeight

        // The three metrics for comparing against the title view.
        // NOTE: `header*` refers to section header metrics, while `title*` refers to navigation
        // bar title metrics. This function will not short unless we're at the edges.
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

        // When scrolling to top/bottom, if the header has visually gone past and below/above the
        // title, commit the switch to the previous/next title. If the header hasn't fully passed
        // the title, add the difference to the offset.
        var offsetChange: CGFloat = 0
        switch collectionView.currentDirections.y {
        case .up: // Offset is decreasing.
            var previousIndex = currentIndex - 1
            if previousDirection == .down && isPassing {
                // If passing of nextIndex cancels, amend state by pretending completion.
                previousDirection = .up
                isPassing = false
                previousIndex = currentIndex
                newIndex += 1
            }
            guard previousIndex >= 0 else { return }
            guard let headerTop = headerTop(at: IndexPath(item: 0, section: newIndex)) else { break }
            // If passed, update new index first.
            if titleBottom < headerTop {
                newIndex = previousIndex
                if isPassing { isPassing = false }
            }
            offsetChange = titleTop - headerTop
            offset = CGFloat(newIndex) * titleHeight
            // If passing.
            if titleTop <= headerTop && abs(offsetChange) <= titleHeight {
                isPassing = true
                offset += offsetChange
            }
        case .down: // Offset is increasing.
            var nextIndex = currentIndex + 1
            if previousDirection == .up && isPassing {
                // If passing of previousIndex cancels, amend state by pretending completion.
                previousDirection = .down
                isPassing = false
                nextIndex = currentIndex
                newIndex -= 1
            }
            guard nextIndex < collectionView.numberOfSections else { return }
            guard let headerTop = headerTop(at: IndexPath(item: 0, section: nextIndex)) else { break }
            // If passed, update new index first.
            if titleTop > headerTop {
                newIndex = nextIndex
                if isPassing { isPassing = false }
            }
            offsetChange = titleBottom - headerTop
            offset = CGFloat(newIndex) * titleHeight
            // If passing.
            if titleBottom >= headerTop && abs(offsetChange) <= titleHeight {
                isPassing = true
                offset += offsetChange
            }
            // print("headerTop: \(headerTop), titleBottom: \(titleBottom), offset: \(offset)")
        }

        // Update.
        titleView.scrollView.setContentOffset(
            CGPoint(x: titleView.scrollView.contentOffset.x, y: offset), animated: false
        )
        // Update state if needed.
        if newIndex != currentSectionIndex {
            // print(currentSectionIndex)
            currentSectionIndex = newIndex
            titleView.updateVisibleItem()
        }
        // print("contentOffset: \(collectionView!.contentOffset.y)")
    }


    @objc func returnBackToTop(_ sender: Any?) {
        isEnabled = false
        collectionView.setContentOffset(
            CGPoint(x: 0, y: -collectionView.contentInset.top),
            animated: true
        )
        titleView.visibleItem = titleView.items.first
    }

}
