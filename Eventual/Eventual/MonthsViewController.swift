//
//  MonthsViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class MonthsViewController: UICollectionViewController, MonthsScreen,
CollectionViewTraitDelegate {

    // MARK: CoordinatedViewController

    weak var currentSegue: UIStoryboardSegue?
    var unwindSegue: Segue?

    // MARK: MonthsScreen

    var currentIndexPath: IndexPath?
    var currentSelectedDayDate: Date?
    var currentSelectedMonthDate: Date?
    var isAddingEventEnabled = true

    var isCurrentItemRemoved: Bool {
        guard let indexPath = currentIndexPath else { return false }
        return events?.day(at: indexPath) != currentSelectedDayDate
    }

    var selectedDayDate: Date? {
        guard let indexPath = currentIndexPath ?? collectionView!.indexPathsForSelectedItems?.first
            else { return nil }
        return events?.day(at: indexPath)
    }

    var selectedMonthDate: Date? {
        guard let indexPath = currentIndexPath ?? collectionView!.indexPathsForSelectedItems?.first
            else { return nil }
        return months?[indexPath.section] as? Date
    }

    var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: Data Source

    fileprivate var events: MonthsEvents? { return flowDataSource.events }
    fileprivate var months: NSArray? { return events?.months }
    fileprivate var needsRestoreStateUpdate = false

    // MARK: Interaction

    fileprivate var backgroundTapTrait: CollectionViewBackgroundTapTrait!
    fileprivate var currentFocusedMonth: Date?
    fileprivate var dataLoadingTrait: CollectionViewDataLoadingTrait!

    fileprivate var deletionTrait: CollectionViewDragDropDeletionTrait!

    // MARK: Layout

    fileprivate var tileLayout: CollectionViewTileLayout {
        return collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: Title View

    @IBOutlet private(set) var titleView: TitleMaskedScrollView!
    fileprivate var titleScrollSyncTrait: CollectionViewTitleScrollSyncTrait!

    // MARK: - Initializers

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.register(
            UINib(nibName: String(describing: DayViewCell.self), bundle: nil),
            forCellWithReuseIdentifier: String(describing: DayViewCell.self)
        )
        setUpAccessibility(specificElement: nil)
        // Title.
        titleView.delegate = self
        titleView.setUp()
        titleView.dataSource = self
        // Layout customization.
        tileLayout.completeSetUp()
        // Traits.
        backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
        backgroundTapTrait.isBarButtonItemEnabled = !Settings.shouldHideAddButtons
        dataLoadingTrait = CollectionViewDataLoadingTrait(delegate: self)
        deletionTrait = CollectionViewDragDropDeletionTrait(delegate: self)
        titleScrollSyncTrait = CollectionViewTitleScrollSyncTrait(delegate: self)
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Observation.
        let center = NotificationCenter.default
        center.addObserver(
            self, selector: #selector(entitiesWereFetched(_:)),
            name: .EntityFetchOperation, object: flowDataSource
        )
        center.addObserver(
            self, selector: #selector(entityWasUpdated(_:)),
            name: .EntityUpdateOperation, object: flowDataSource
        )
        // In case new sections have been added from new events.
        refreshTitleState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView!.updateBackgroundOnAppearance(animated: true)
        if events == nil {
            UIApplication.shared.sendAction(.refreshEvents, from: self)
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(
            alongsideTransition: { context in self.tileLayout.invalidateLayout() },
            completion: nil
        )
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        currentSegue = segue
        UIApplication.shared.sendAction(.prepareSegueForDescendant, from: self)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        if let dayDate = currentSelectedDayDate,
            let monthDate = currentSelectedMonthDate,
            let indexPath = currentIndexPath {
            coder.encode(dayDate, forKey: #keyPath(currentSelectedDayDate))
            coder.encode(monthDate, forKey: #keyPath(currentSelectedMonthDate))
            coder.encode(indexPath, forKey: #keyPath(currentIndexPath))
        }
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        if let dayDate = coder.decodeObject(forKey: #keyPath(currentSelectedDayDate)) as? Date,
            let monthDate = coder.decodeObject(forKey: #keyPath(currentSelectedMonthDate)) as? Date,
            let indexPath = coder.decodeObject(forKey: #keyPath(currentIndexPath)) as? IndexPath,
            dayDate > Date().dayDate {
            needsRestoreStateUpdate = true
            currentSelectedDayDate = dayDate
            currentSelectedMonthDate = monthDate
            currentIndexPath = indexPath
        }
    }

    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()
    }

    // MARK: Handlers

    func settingsDidChange(_ notification: Notification) {
        backgroundTapTrait?.isBarButtonItemEnabled = !Settings.shouldHideAddButtons
    }

    func entitiesWereFetched(_ notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard let _ = notification.userInfo?.notificationUserInfoPayload() as? EntitiesFetchedPayload
            else { return }

        if needsRestoreStateUpdate,
            let dayDate = currentSelectedDayDate, let monthDate = currentSelectedMonthDate {
            currentIndexPath = events!.indexPathForDay(of: dayDate, monthDate: monthDate)
        }

        dataLoadingTrait.dataDidLoad()

        // In case new sections have been added from new events.
        refreshTitleState(canScrollToTop: true)
    }

    func entityWasUpdated(_ notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard let events = events, let collectionView = collectionView,
            let payload = notification.userInfo?.notificationUserInfoPayload() as? EntityUpdatedPayload
            else { return }

        // Update associated state.
        if let event = payload.event,
            let nextIndexPath = events.indexPathForDay(of: event.startDate.dayDate),
            nextIndexPath != currentIndexPath {
            currentIndexPath = nextIndexPath
        }

        let updatingInfo = events.indexPathUpdatesForEvent(
            newInfo: (event: payload.event, indexPath: payload.presave.toIndexPath),
            oldInfo: (event: payload.presave.event, indexPath: payload.presave.fromIndexPath)
        )

        collectionView.performBatchUpdates({
            collectionView.deleteSections(updatingInfo.sectionDeletions)
            collectionView.deleteItems(at: updatingInfo.deletions)
            collectionView.insertSections(updatingInfo.sectionInsertions)
            collectionView.insertItems(at: updatingInfo.insertions)
            collectionView.reloadItems(at: updatingInfo.reloads)

        }) { finished in
            guard finished &&
                (updatingInfo.sectionDeletions.count > 0 || updatingInfo.sectionInsertions.count > 0)
                else { return }

            self.refreshTitleState()
        }
    }

    // MARK: - Actions

    @objc private func handleRefresh(_ sender: UIRefreshControl) {
        UIApplication.shared.sendAction(.refreshEvents, from: self)
    }

    @IBAction private func prepareForUnwindSegue(_ sender: UIStoryboardSegue) {
        currentSegue = sender
        UIApplication.shared.sendAction(.prepareSegueForDescendant, from: self)
    }

}

// MARK: -

// MARK: CollectionViewBackgroundTapTraitDelegate

extension MonthsViewController: CollectionViewBackgroundTapTraitDelegate {

    func backgroundTapTraitDidToggleHighlight(at location: CGPoint) {
        guard let month = currentFocusedMonth, let events = events,
            let months = months as? [Date], var index = months.index(of: month)
            else { preconditionFailure() }
        var nextIndex = index + 1
        while nextIndex < months.count {
            let indexPath = IndexPath(item: 0, section: nextIndex)
            let origin = tileLayout.layoutAttributesForSupplementaryView(
                ofKind: UICollectionElementKindSectionHeader, at: indexPath)!.frame.origin
            guard origin.y < location.y else { break }
            index = nextIndex
            nextIndex += 1
        }
        currentSelectedMonthDate = months[index]
        if let lastDay = events.eventsForMonth(at: index)?.lastDay {
            currentSelectedMonthDate = (
                lastDay.isLastDayInMonth ? lastDay : lastDay.dayDate(byAddingDays: 1)
            )
        }
        if Date().dayDate > currentSelectedMonthDate! {
            currentSelectedMonthDate = Date().dayDate
        }
        self.performSegue(withIdentifier: Segue.addEvent.rawValue, sender: nil)
    }

    func backgroundTapTraitFallbackBarButtonItem() -> UIBarButtonItem {
        let buttonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self, action: #selector(backgroundTapTraitDidToggleHighlight(at:))
        )
        setUpAccessibility(specificElement: buttonItem)
        return buttonItem
    }

}

// MARK: CollectionViewDragDropDeletionTraitDelegate

extension MonthsViewController: CollectionViewDragDropDeletionTraitDelegate {

    func canDeleteCellOnDrop(cellFrame: CGRect) -> Bool {
        return tileLayout.canDeleteCellOnDrop(cellFrame: cellFrame)
    }

    func canDragCell(at cellIndexPath: IndexPath) -> Bool {
        guard let dayEvents =  events?.eventsForDay(at: cellIndexPath) as? [Event]
            else { return false }
        return dayEvents.reduce(true) { return $0 && $1.calendar.allowsContentModifications }
    }

    func deleteDroppedCell(_ cell: UIView, completion: () -> Void) throws {
        let dayEvents = events!.eventsForDay(at: currentIndexPath!) as! [Event]
        try flowDataSource.remove(dayEvents: dayEvents)
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
        let shouldDeleteSection = collectionView!.numberOfItems(inSection: cellIndexPath.section) == 1
        collectionView!.performBatchUpdates({
            if shouldDeleteSection {
                self.collectionView!.deleteSections(IndexSet(integer: cellIndexPath.section))
            }
            self.collectionView!.deleteItems(at: [cellIndexPath])
        }) { finished in
            guard finished && shouldDeleteSection else { return }
            self.refreshTitleState()
        }
        tileLayout.isDeletionDropzoneHidden = true
    }

    func didStartDraggingCellForDeletion(at cellIndexPath: IndexPath) {
        currentIndexPath = cellIndexPath
        tileLayout.isDeletionDropzoneHidden = false
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension MonthsViewController: CollectionViewZoomTransitionTraitDelegate {

    func zoomTransition(_ transition: ZoomTransition,
                        subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView] {
        return [cell.innerContentView]
    }

}

// MARK: - Title View

// MARK: CollectionViewTitleScrollSyncTraitDelegate

extension MonthsViewController: CollectionViewTitleScrollSyncTraitDelegate {

    var currentVisibleContentYOffset: CGFloat {
        let scrollView = collectionView!
        var offset = scrollView.contentOffset.y
        if edgesForExtendedLayout.contains(.top) {
            offset += topLayoutGuide.length
        }
        return offset
    }

    func titleScrollSyncTraitLayoutAttributes(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return tileLayout.layoutAttributesForSupplementaryView(
            ofKind: UICollectionElementKindSectionHeader, at: indexPath
        )
    }

    // MARK: UIScrollViewDelegate

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        titleScrollSyncTrait.isEnabled = true
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        dataLoadingTrait.reloadIfNeeded()
        titleScrollSyncTrait.isEnabled = false
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dataLoadingTrait.reloadIfNeeded()
        titleScrollSyncTrait.isEnabled = false
    }

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        titleScrollSyncTrait.isEnabled = true
        titleScrollSyncTrait.currentSectionIndex = 0
        collectionView!.tearDownCurrentDirectionsState()
    }

}

// MARK: TitleScrollViewDataSource

extension MonthsViewController: TitleScrollViewDataSource {

    fileprivate func refreshTitleState(canScrollToTop: Bool = false) {
        if let months = months {
            let didMonthsChange = currentFocusedMonth != nil && !months.contains(currentFocusedMonth!)
            if currentFocusedMonth == nil || didMonthsChange {
                currentFocusedMonth = months.firstObject as? Date
            }
            if canScrollToTop && didMonthsChange {
                DispatchQueue.main.async {
                    self.titleScrollSyncTrait.returnBackToTop(self)
                }
            }
        }
        titleView.refreshItems()
    }

    func titleScrollViewItemCount(_ scrollView: TitleScrollView) -> Int {
        guard let months = months, months.count > 0 else { return 1 }
        return numberOfSections(in: collectionView!)
    }

    func titleScrollView(_ scrollView: TitleScrollView, itemAt index: Int) -> UIView? {
        guard scrollView == titleView.scrollView else { return nil }
        guard let month = events?.month(at: index) else {
            // Default to app title.
            return scrollView.newItem(type: .label, text: Bundle.appName!.uppercased())
        }
        let text = MonthHeaderView.formattedText(for: month)
        let label = scrollView.newItem(type: .label, text: text)
        if index == 0 {
            renderAccessibilityValue(for: scrollView, value: label)
        }
        return label
    }

}

// MARK: TitleScrollViewDelegate

extension MonthsViewController: TitleScrollViewDelegate {

    func titleScrollView(_ scrollView: TitleScrollView, didChangeVisibleItem visibleItem: UIView) {
        renderAccessibilityValue(for: scrollView, value: visibleItem)
        if let index = scrollView.items.index(of: visibleItem) {
            currentFocusedMonth = months?[index] as? Date
        }
    }

}

// MARK: - Data

extension MonthsViewController {

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return events?.daysForMonth(at: section)?.count ?? 0
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return months?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: DayViewCell.self), for: indexPath
        )
        if let cell = cell as? DayViewCell, let dayDate = events?.day(at: indexPath),
            let monthDate = months?[indexPath.section] as? Date,
            let dayEvents = events?.events(forMonth: monthDate).events(forDay: dayDate) {
            DayViewCell.render(cell: cell, fromDayEvents: dayEvents, dayDate: dayDate, monthDate: monthDate)
            cell.setUpAccessibility(at: indexPath)
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: String(describing: MonthHeaderView.self), for: indexPath
        )
        if case kind = UICollectionElementKindSectionHeader,
            let headerView = view as? MonthHeaderView,
            let monthDate = months?[indexPath.section] as? Date {
            headerView.monthDate = monthDate
            headerView.monthLabel.textColor = Appearance.lightGrayTextColor
        }
        return view
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 willDisplay cell: UICollectionViewCell,
                                 forItemAt indexPath: IndexPath) {

        guard let count = months?.count else { return }
        let isPastThreshold = indexPath.section == count - 1
        guard isPastThreshold else { return }
        UIApplication.shared.sendAction(.fetchMoreEvents, from: self)
    }

}

// MARK: - Day Cell

extension MonthsViewController {

    fileprivate func tileCell(at indexPath: IndexPath) -> CollectionViewTileCell? {
        return collectionView?.cellForItem(at: indexPath) as? CollectionViewTileCell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView,
                                 shouldSelectItemAt indexPath: IndexPath) -> Bool {
        currentIndexPath = indexPath
        return true
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didHighlightItemAt indexPath: IndexPath) {
        tileCell(at: indexPath)?.animateHighlighted()
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didUnhighlightItemAt indexPath: IndexPath) {
        tileCell(at: indexPath)?.animateUnhighlighted()
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: Segue.showDay.rawValue, sender: nil)
    }

}

// MARK: - Layout

// MARK: UICollectionViewDelegateFlowLayout

extension MonthsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section > 0 else { return CGSize(width: 0.01, height: 0.01) } // Still add, but hide.
        return (collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize ?? .zero
    }

}
