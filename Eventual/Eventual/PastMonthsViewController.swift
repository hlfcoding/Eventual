//
//  PastMonthsViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class PastMonthsViewController: UICollectionViewController, ArchiveScreen,
CollectionViewTraitDelegate {

    // MARK: CoordinatedViewController

    weak var currentSegue: UIStoryboardSegue?
    var unwindSegue: Segue?

    // MARK: ArchiveScreen

    var currentIndexPath: IndexPath?
    var currentSelectedMonthDate: Date?
    var isAddingEventEnabled = false

    var isCurrentItemRemoved: Bool {
        guard let indexPath = currentIndexPath else { return false }
        return events?.month(at: indexPath.item) != currentSelectedMonthDate
    }

    var selectedMonthDate: Date? {
        guard let indexPath = currentIndexPath ?? collectionView!.indexPathsForSelectedItems?.first
            else { return nil }
        return events?.month(at: indexPath.item)
    }

    var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: Data Source

    fileprivate var events: MonthsEvents? { return flowDataSource.events }
    fileprivate var months: NSArray? { return events?.months }

    // MARK: Interaction

    fileprivate var dataLoadingTrait: CollectionViewDataLoadingTrait!
    fileprivate var swipeDismissalTrait: ViewControllerSwipeDismissalTrait!

    // MARK: - Initializers

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        title = t("Archive", "bar title").uppercased()
        collectionView!.backgroundColor = Appearance.collectionViewBackgroundColor
        // Traits.
        dataLoadingTrait = CollectionViewDataLoadingTrait(delegate: self)
        if events != nil {
            dataLoadingTrait.dataDidLoad()
        }
        swipeDismissalTrait = ViewControllerSwipeDismissalTrait(viewController: self) { [unowned self] in
            self.performSegue(withIdentifier: self.unwindSegue!.rawValue, sender: nil)
        }
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Observation.
        NotificationCenter.default.addObserver(
            self, selector: #selector(entitiesWereFetched(_:)),
            name: .EntityFetchOperation, object: flowDataSource
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if events == nil {
            UIApplication.shared.sendAction(.refreshEvents, from: self)
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionViewLayout.invalidateLayout()
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        currentSegue = segue
        UIApplication.shared.sendAction(.prepareSegueForDescendant, from: self)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }

    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()
    }

    // MARK: Handlers

    @objc private func entitiesWereFetched(_ notification: Notification) {
        // NOTE: This will run even when this screen isn't visible.
        guard let _ = notification.userInfo?.notificationUserInfoPayload() as? EntitiesFetchedPayload
            else { return }

        dataLoadingTrait.dataDidLoad()
    }

    // MARK: Actions

    @objc private func handleRefresh(_ sender: UIRefreshControl) {
        UIApplication.shared.sendAction(.refreshEvents, from: self)
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension PastMonthsViewController: CollectionViewZoomTransitionTraitDelegate {

    func zoomTransitionFrameFitting(_ transition: ZoomTransition) -> String {
        return ZoomTransitionFrameFitting.zoomedOutAspectFittingZoomedIn.rawValue
    }

    func zoomTransitionViewIntersection(_ transition: ZoomTransition) -> String {
        return ZoomTransitionViewIntersection.zoomedOutView.rawValue
    }

    func zoomTransition(_ transition: ZoomTransition,
                        originForZoomedOutFrameZoomedIn frame: CGRect) -> CGPoint {
        return CGPoint(x: frame.origin.x, y: topLayoutGuide.length)
    }

    func zoomTransition(_ transition: ZoomTransition,
                        originForZoomedInFrameZoomedOut frame: CGRect) -> CGPoint {
        let y = transition.zoomedOutFrame.origin.y - topLayoutGuide.length * transition.aspectFittingScale
        return CGPoint(x: frame.origin.x, y: y)
    }

    func zoomTransition(_ transition: ZoomTransition,
                        viewForCell cell: UICollectionViewCell) -> UIView {
        guard let cell = cell as? MonthViewCell else { preconditionFailure() }
        return cell.tilesView!
    }

}

// MARK: - Data

extension PastMonthsViewController {

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return events?.months.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: MonthViewCell.self), for: indexPath
        )
        if let cell = cell as? MonthViewCell, let monthDate = events?.month(at: indexPath.item),
            let monthEvents = events?.eventsForMonth(of: monthDate) {
            MonthViewCell.render(cell: cell, fromMonthEvents: monthEvents, monthDate: monthDate)
            cell.setUpAccessibility(at: indexPath)
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 willDisplay cell: UICollectionViewCell,
                                 forItemAt indexPath: IndexPath) {
        guard let count = months?.count else { return }
        let isPastThreshold = indexPath.item >= count - 4
        guard isPastThreshold else { return }
        UIApplication.shared.sendAction(.fetchMoreEvents, from: self)
    }

}

// MARK: - Month Cell

extension PastMonthsViewController: UICollectionViewDelegateFlowLayout {

    // MARK: UIScrollViewDelegate

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        dataLoadingTrait.reloadIfNeeded()
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dataLoadingTrait.reloadIfNeeded()
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView,
                                 shouldSelectItemAt indexPath: IndexPath) -> Bool {
        currentIndexPath = indexPath
        return true
    }

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let monthDate = events?.month(at: indexPath.item),
            let monthEvents = events?.eventsForMonth(of: monthDate)
            else { return .zero }
        let cellSizes = MonthViewCellSizes(sizeClass: traitCollection.horizontalSizeClass)
        let tiles = min(cellSizes.maxTileRowCount * cellSizes.defaultTileColumnCount,
                        monthEvents.days.count)
        let rows = ceil(CGFloat(tiles) / CGFloat(cellSizes.defaultTileColumnCount))
        let expand = cellSizes.tileSize * max(0, rows - CGFloat(cellSizes.defaultTileRowCount))
        var size = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        size.height += expand
        size.width = collectionView.bounds.width
        return size
    }

}
