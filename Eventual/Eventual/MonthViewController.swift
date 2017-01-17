//
//  MonthViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class MonthViewController: UICollectionViewController, MonthScreen {

    // MARK: CoordinatedViewController

    weak var coordinator: NavigationCoordinatorProtocol?
    func finishRestoringState() {
        if let selectedDayDate = currentSelectedDayDate {
            currentIndexPath = IndexPath(item: days!.index(of: selectedDayDate), section: 0)
        }
    }

    // MARK: MonthsScreen

    var currentIndexPath: IndexPath?
    var currentSelectedDayDate: Date?
    var monthDate: Date!

    var isCurrentItemRemoved: Bool {
        guard let indexPath = currentIndexPath else { return false }
        return events?.days[indexPath.item] as? Date != currentSelectedDayDate
    }

    var selectedDayDate: Date? {
        guard let indexPath = currentIndexPath ?? collectionView!.indexPathsForSelectedItems?.first
            else { return nil }
        return events?.days[indexPath.item] as? Date
    }

    var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: Data Source

    fileprivate var events: MonthEvents? { return coordinator?.monthsEvents?.eventsForMonth(of: monthDate) }
    fileprivate var days: NSArray? { return events?.days }

    // MARK: Interaction

    fileprivate var backgroundTapTrait: CollectionViewBackgroundTapTrait!
    fileprivate var deletionTrait: CollectionViewDragDropDeletionTrait!

    // MARK: Layout

    fileprivate var tileLayout: CollectionViewTileLayout {
        return collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: - Initializers

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.register(
            UINib(nibName: String(describing: DayViewCell.self), bundle: nil),
            forCellWithReuseIdentifier: String(describing: DayViewCell.self)
        )
        // setUpAccessibility(specificElement: nil)
        // Layout customization.
        tileLayout.completeSetUp()
        // Traits.
        backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
        backgroundTapTrait.isEnabled = Appearance.shouldTapToAddEvent
        deletionTrait = CollectionViewDragDropDeletionTrait(delegate: self)
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Title.
        title = DateFormatter.monthFormatter.string(from: monthDate).uppercased()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        backgroundTapTrait.updateOnAppearance(animated: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(
            alongsideTransition: { context in self.tileLayout.invalidateLayout() },
            completion: nil
        )
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        coordinator?.prepare(for: segue, sender: sender)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        if let dayDate = currentSelectedDayDate, let indexPath = currentIndexPath {
            coder.encode(dayDate, forKey: #keyPath(currentSelectedDayDate))
            coder.encode(indexPath, forKey: #keyPath(currentIndexPath))
        }
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        if let dayDate = coder.decodeObject(forKey: #keyPath(currentSelectedDayDate)) as? Date,
            let indexPath = coder.decodeObject(forKey: #keyPath(currentIndexPath)) as? IndexPath,
            dayDate > Date().dayDate {
            currentSelectedDayDate = dayDate
            currentIndexPath = indexPath
        }
        let coordinator = AppDelegate.sharedDelegate.mainCoordinator
        coordinator.pushRestoringScreen(self)
        self.coordinator = coordinator
    }

    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()
    }

    // MARK: - Actions

    @IBAction private func prepareForUnwindSegue(_ sender: UIStoryboardSegue) {
        coordinator?.prepare(for: sender, sender: nil)
    }

}

// MARK: -

// MARK: CollectionViewBackgroundTapTraitDelegate

extension MonthViewController: CollectionViewBackgroundTapTraitDelegate {

    func backgroundTapTraitDidToggleHighlight(at location: CGPoint) {
        coordinator?.performNavigationAction(for: .backgroundTap, viewController: self)
    }

    func backgroundTapTraitFallbackBarButtonItem() -> UIBarButtonItem {
        let buttonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self, action: #selector(backgroundTapTraitDidToggleHighlight(at:))
        )
        // setUpAccessibility(specificElement: buttonItem)
        return buttonItem
    }

}

// MARK: CollectionViewDragDropDeletionTraitDelegate

extension MonthViewController: CollectionViewDragDropDeletionTraitDelegate {

    func canDeleteCellOnDrop(cellFrame: CGRect) -> Bool {
        return tileLayout.canDeleteCellOnDrop(cellFrame: cellFrame)
    }

    func canDragCell(at cellIndexPath: IndexPath) -> Bool {
        guard let dayEvents = events?.events[cellIndexPath.item] as? [Event]
            else { return false }
        return dayEvents.reduce(true) { return $0 && $1.calendar.allowsContentModifications }
    }

    func deleteDroppedCell(_ cell: UIView, completion: () -> Void) throws {
        guard let coordinator = coordinator, let indexPath = currentIndexPath,
            let dayEvents = events?.events[indexPath.item] as? [Event]
            else { preconditionFailure() }
        try coordinator.remove(dayEvents: dayEvents)
        completion()
    }

    func finalFrameForDroppedCell() -> CGRect {
        return tileLayout.finalFrameForDroppedCell()
    }

    func maxYForDraggingCell() -> CGFloat {
        return tileLayout.maxYForDraggingCell()
    }

    func minYForDraggingCell() -> CGFloat {
        return 0
    }

    func didCancelDraggingCellForDeletion(at cellIndexPath: IndexPath) {
        currentIndexPath = nil
        tileLayout.isDeletionDropzoneHidden = true
    }

    func didRemoveDroppedCellAfterDeletion(at cellIndexPath: IndexPath) {
        currentIndexPath = nil
        collectionView!.performBatchUpdates({
            self.collectionView!.deleteItems(at: [cellIndexPath])
        }, completion: nil)
        tileLayout.isDeletionDropzoneHidden = true
    }

    func didStartDraggingCellForDeletion(at cellIndexPath: IndexPath) {
        currentIndexPath = cellIndexPath
        tileLayout.isDeletionDropzoneHidden = false
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension MonthViewController: CollectionViewZoomTransitionTraitDelegate {

    func animatedTransition(_ transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView] {
        return [cell.innerContentView]
    }

}

// MARK: - Data

extension MonthViewController {

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return days?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: DayViewCell.self), for: indexPath
        )
        if let cell = cell as? DayViewCell, let dayDate = days?[indexPath.item] as? Date,
            let dayEvents = events?.events[indexPath.item] as? DayEvents {
            DayViewCell.render(cell: cell, fromDayEvents: dayEvents, dayDate: dayDate)
            cell.setUpAccessibility(at: indexPath)
        }
        return cell
    }

}

// MARK: - Day Cell

extension MonthViewController {

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView,
                                 shouldSelectItemAt indexPath: IndexPath) -> Bool {
        currentIndexPath = indexPath
        return true
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didHighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewTileCell
            else { return }
        cell.animateHighlighted()
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewTileCell
            else { return }
        cell.animateUnhighlighted()
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: Segue.showDay.rawValue, sender: nil)
    }

}

// MARK: - Layout

// MARK: UICollectionViewDelegateFlowLayout

extension MonthViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section > 0 else { return CGSize(width: 0.01, height: 0.01) } // Still add, but hide.
        return (collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize ?? .zero
    }

}