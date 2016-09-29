//
//  MonthsViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class MonthsViewController: UICollectionViewController, MonthsScreen {

    // MARK: CoordinatedViewController

    weak var coordinator: NavigationCoordinatorProtocol?

    // MARK: MonthsScreen

    var currentIndexPath: IndexPath?
    var currentSelectedDayDate: Date?

    var isCurrentItemRemoved: Bool {
        guard let indexPath = currentIndexPath else { return false }
        return events?.day(at: indexPath) != currentSelectedDayDate
    }

    var selectedDayDate: Date? {
        guard let indexPath = currentIndexPath ?? collectionView!.indexPathsForSelectedItems?.first
            else { return nil }
        return events?.day(at: indexPath)
    }

    var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: Data Source

    fileprivate var events: MonthsEvents? { return coordinator?.monthsEvents }
    fileprivate var months: NSArray? { return events?.months }

    // MARK: Interaction

    @IBOutlet private(set) var backgroundTapRecognizer: UITapGestureRecognizer!
    fileprivate var backgroundTapTrait: CollectionViewBackgroundTapTrait!

    @IBOutlet private(set) var backToTopTapRecognizer: UITapGestureRecognizer!

    var deletionTrait: CollectionViewDragDropDeletionTrait!

    // MARK: Layout

    fileprivate var tileLayout: CollectionViewTileLayout {
        return collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: Title View

    @IBOutlet private(set) var titleView: NavigationTitleMaskedScrollView!
    fileprivate var titleScrollSyncTrait: CollectionViewTitleScrollSyncTrait!

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
        customizeNavigationItem()

        let center = NotificationCenter.default
        center.addObserver(
            self, selector: #selector(applicationDidBecomeActive(notification:)),
            name: .UIApplicationDidBecomeActive, object: nil
        )
        center.addObserver(
            self, selector: #selector(entityFetchOperationDidComplete(notification:)),
            name: .EntityFetchOperation, object: nil
        )
        center.addObserver(
            self, selector: #selector(entityUpdateOperationDidComplete(notification:)),
            name: .EntityUpdateOperation, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAccessibility(specificElement: nil)
        // Title.
        titleView.delegate = self
        titleView.dataSource = self
        // Layout customization.
        tileLayout.register(UINib(nibName: String(describing: EventDeletionDropzoneView.self), bundle: Bundle.main),
                            forDecorationViewOfKind: CollectionViewTileLayout.deletionViewKind)
        // Traits.
        backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
        backgroundTapTrait.isEnabled = Appearance.isMinimalismEnabled
        deletionTrait = CollectionViewDragDropDeletionTrait(delegate: self)
        titleScrollSyncTrait = CollectionViewTitleScrollSyncTrait(delegate: self)
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // In case new sections have been added from new events.
        titleView.refreshSubviews()
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

    // MARK: Handlers

    func applicationDidBecomeActive(notification: NSNotification) {
        // In case settings change.
        if let backgroundTapTrait = backgroundTapTrait {
            backgroundTapTrait.isEnabled = Appearance.isMinimalismEnabled
        }
    }

    func entityFetchOperationDidComplete(notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard
            let payload = notification.userInfo?.notificationUserInfoPayload() as? EntitiesFetchedPayload,
            case payload.fetchType = EntitiesFetched.upcomingEvents
            else { return }

        collectionView!.reloadData()

        // In case new sections have been added from new events.
        titleView.refreshSubviews()
    }

    func entityUpdateOperationDidComplete(notification: NSNotification) {
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
            newEventInfo: (event: payload.event, currentIndexPath: payload.presave.toIndexPath),
            oldEventInfo: (event: payload.presave.event, currentIndexPath: payload.presave.fromIndexPath)
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

            self.titleView.refreshSubviews()
        }
    }

    // MARK: - Actions

    @IBAction private func prepareForUnwindSegue(_ sender: UIStoryboardSegue) {
        coordinator?.prepare(for: sender, sender: nil)
    }

    @IBAction private func returnBackToTop(_ sender: UITapGestureRecognizer) {
        collectionView!.setContentOffset(
            CGPoint(x: 0, y: -collectionView!.contentInset.top),
            animated: true
        )
    }
    
}

// MARK: CollectionViewBackgroundTapTraitDelegate

extension MonthsViewController: CollectionViewBackgroundTapTraitDelegate {

    func backgroundTapTraitDidToggleHighlight() {
        coordinator?.performNavigationAction(for: .backgroundTap, viewController: self)
    }

    func backgroundTapTraitFallbackBarButtonItem() -> UIBarButtonItem {
        let buttonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self, action: #selector(backgroundTapTraitDidToggleHighlight)
        )
        setUpAccessibility(specificElement: buttonItem)
        return buttonItem
    }

}

// MARK: CollectionViewDragDropDeletionTraitDelegate

extension MonthsViewController: CollectionViewDragDropDeletionTraitDelegate {

    func canDeleteCellOnDrop(cellFrame: CGRect) -> Bool {
        return tileLayout.deletionDropZoneAttributes?.frame.intersects(cellFrame) ?? false
    }

    func canDragCell(at cellIndexPath: IndexPath) -> Bool {
        guard let dayEvents =  events?.eventsForDay(at: cellIndexPath) as? [Event]
            else { return false }
        return dayEvents.reduce(true) { return $0 && $1.calendar.allowsContentModifications }
    }

    func deleteDroppedCell(_ cell: UIView, completion: () -> Void) throws {
        guard let coordinator = coordinator, let indexPath = currentIndexPath,
            let dayEvents = events?.eventsForDay(at: indexPath) as? [Event]
            else { preconditionFailure() }
        try coordinator.remove(dayEvents: dayEvents)
        completion()
    }

    func finalFrameForDroppedCell() -> CGRect {
        guard let dropZoneAttributes = tileLayout.deletionDropZoneAttributes
            else { preconditionFailure() }
        return CGRect(origin: dropZoneAttributes.center, size: .zero)
    }

    func maxYForDraggingCell() -> CGFloat {
        guard let collectionView = collectionView else { preconditionFailure() }
        return (collectionView.bounds.height + collectionView.contentOffset.y
            - tileLayout.deletionDropZoneHeight + CollectionViewTileCell.borderSize)
    }

    func minYForDraggingCell() -> CGFloat {
        guard let collectionView = collectionView else { preconditionFailure() }
        return collectionView.bounds.minY + tileLayout.viewportYOffset
    }

    func didCancelDraggingCellForDeletion(at cellIndexPath: IndexPath) {
        currentIndexPath = nil
        tileLayout.deletionDropZoneHidden = true
    }

    func didRemoveDroppedCellAfterDeletion(at cellIndexPath: IndexPath) {
        guard let collectionView = collectionView else { preconditionFailure() }
        currentIndexPath = nil
        let shouldDeleteSection = collectionView.numberOfItems(inSection: cellIndexPath.section) == 1
        collectionView.performBatchUpdates({
            if shouldDeleteSection {
                collectionView.deleteSections(IndexSet(integer: cellIndexPath.section))
            }
            collectionView.deleteItems(at: [cellIndexPath])
        }) { finished in
            if finished && shouldDeleteSection {
                self.titleView.refreshSubviews()
            }
        }
        tileLayout.deletionDropZoneHidden = true
    }

    func willStartDraggingCellForDeletion(at cellIndexPath: IndexPath) {
        currentIndexPath = cellIndexPath
        tileLayout.deletionDropZoneHidden = false
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension MonthsViewController: CollectionViewZoomTransitionTraitDelegate {

    func animatedTransition(_ transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView] {
        return [cell.innerContentView]
    }

}

// MARK: - Title View

extension MonthsViewController: CollectionViewTitleScrollSyncTraitDelegate {

    var currentVisibleContentYOffset: CGFloat {
        let scrollView = collectionView!
        var offset = scrollView.contentOffset.y
        //print(offset, tileLayout.viewportYOffset)
        if edgesForExtendedLayout.contains(.top) {
            offset += tileLayout.viewportYOffset
        }
        return offset
    }

    func titleScrollSyncTraitLayoutAttributes(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return tileLayout.layoutAttributesForSupplementaryView(
            ofKind: UICollectionElementKindSectionHeader, at: indexPath
        )
    }

    // MARK: UIScrollViewDelegate

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard events != nil else { return }
        titleScrollSyncTrait.syncTitleViewContentOffsetsWithSectionHeader()
    }

}

// MARK: NavigationTitleScrollViewDataSource

extension MonthsViewController: NavigationTitleScrollViewDataSource {

    func navigationTitleScrollViewItemCount(_ scrollView: NavigationTitleScrollView) -> Int {
        guard let months = months , months.count > 0 else { return 1 }
        return numberOfSections(in: collectionView!)
    }

    func navigationTitleScrollView(_ scrollView: NavigationTitleScrollView,
                                   itemAt index: Int) -> UIView? {
        guard scrollView == titleView.scrollView else { return nil }
        guard let month = events?.month(at: index) else {
            guard let info = Bundle.main.infoDictionary,
                let text = (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String)
                else { return nil }
            // Default to app title.
            return scrollView.newItem(type: .label, text: text)
        }
        let text = MonthHeaderView.formattedText(for: DateFormatter.monthFormatter.string(from: month))
        let label = scrollView.newItem(type: .label, text: MonthHeaderView.formattedText(for: text))
        if index == 0 {
            renderAccessibilityValue(for: scrollView, value: label)
        }
        return label
    }

}

// MARK: NavigationTitleScrollViewDelegate

extension MonthsViewController: NavigationTitleScrollViewDelegate {

    func navigationTitleScrollView(_ scrollView: NavigationTitleScrollView,
                                   didChangeVisibleItem visibleItem: UIView) {
        renderAccessibilityValue(for: scrollView, value: visibleItem)
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
            let dayEvents = events?.eventsForDay(at: indexPath) {
            DayViewCell.render(cell: cell, fromDayEvents: dayEvents, dayDate: dayDate)
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
            let month = months?[indexPath.section] as? Date {
            headerView.monthName = DateFormatter.monthFormatter.string(from: month)
            headerView.monthLabel.textColor = Appearance.lightGrayTextColor
        }
        return view
    }

}

// MARK: - Day Cell

extension MonthsViewController {

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

}

// MARK: - Layout

extension MonthsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section > 0 else { return CGSize(width: 0.01, height: 0.01) } // Still add, but hide.
        return (collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize ?? .zero
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return tileLayout.sizeForItem(at: indexPath)
    }

}
