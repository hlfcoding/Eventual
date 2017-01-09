//
//  PastMonthsViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class PastMonthsViewController: UICollectionViewController, ArchiveScreen {

    // MARK: CoordinatedViewController

    weak var coordinator: NavigationCoordinatorProtocol?

    func finishRestoringState() {}

    // MARK: ArchiveScreen

    var currentIndexPath: IndexPath?
    var currentSelectedMonthDate: Date?

    var isCurrentItemRemoved: Bool {
        guard let indexPath = currentIndexPath else { return false }
        return events?.month(at: indexPath.item) != currentSelectedMonthDate
    }

    var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: Data Source

    fileprivate var events: MonthsEvents? { return coordinator?.monthsEvents }
    fileprivate var months: NSArray? { return events?.months }

    // MARK: - Initializers

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    private func setUp() {
        let center = NotificationCenter.default
        center.addObserver(
            self, selector: #selector(entityFetchOperationDidComplete(notification:)),
            name: .EntityFetchOperation, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        title = t("Archive", "bar title").uppercased()
        collectionView!.backgroundColor = Appearance.collectionViewBackgroundColor
        // Traits.
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        coordinator?.prepare(for: segue, sender: sender)
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

    func entityFetchOperationDidComplete(notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard
            let payload = notification.userInfo?.notificationUserInfoPayload() as? EntitiesFetchedPayload,
            case payload.fetchType = EntitiesFetched.pastEvents
            else { return }

        collectionView!.reloadData()
    }

    // MARK: Actions

    @IBAction private func prepareForUnwindSegue(_ segue: UIStoryboardSegue) {
        coordinator?.prepare(for: segue, sender: nil)
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension PastMonthsViewController: CollectionViewZoomTransitionTraitDelegate {

    func animatedTransition(_ transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView] {
        return []
    }

//    func animatedTransition(_ transition: AnimatedTransition,
//                            subviewsToAnimateSeparatelyForReferenceCell cell: UICollectionViewCell) -> [UIView] {
//        guard let cell = cell as? MonthViewCell else { preconditionFailure() }
//        return [cell.tilesView]
//    }

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

}

// MARK: - Month Cell

extension PastMonthsViewController {

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView,
                                 shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

}
