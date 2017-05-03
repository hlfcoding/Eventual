//
//  DayViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class DayViewController: UICollectionViewController, DayScreen {

    // MARK: CoordinatedViewController

    weak var currentSegue: UIStoryboardSegue?
    var unwindSegue: Segue?

    // MARK: DayScreen

    var currentIndexPath: IndexPath?
    var currentSelectedEvent: Event?
    var dayDate: Date!
    var monthDate: Date!
    var isAddingEventEnabled = true

    var isCurrentItemRemoved: Bool {
        guard dayDate != RecurringDate else { return false }

        guard let indexPath = currentIndexPath, events.count > indexPath.item,
            let event = currentSelectedEvent
            else { return true }

        return event.startDate.dayDate != dayDate
    }

    var selectedEvent: Event? {
        guard let indexPath = currentIndexPath, events.count > indexPath.item
            else { return nil }

        return event(at: indexPath.item)
    }

    var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: Data Source

    @objc fileprivate var events: [Any] = []

    // MARK: Interaction

    fileprivate var backgroundTapTrait: CollectionViewBackgroundTapTrait?
    fileprivate var deletionTrait: CollectionViewDragDropDeletionTrait!
    fileprivate var swipeDismissalTrait: ViewControllerSwipeDismissalTrait!

    // MARK: Layout

    fileprivate var tileLayout: CollectionViewTileLayout {
        return collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: - Initializers

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAccessibility(specificElement: nil)
        // Data.
        updateData(andReload: false)
        // Layout customization.
        tileLayout.completeSetUp()
        tileLayout.dynamicNumberOfColumns = false
        // Observation.
        Settings.addChangeObserver(self, selector: #selector(settingsDidChange(_:)))
        // Traits.
        deletionTrait = CollectionViewDragDropDeletionTrait(delegate: self)
        swipeDismissalTrait = ViewControllerSwipeDismissalTrait(viewController: self) { [unowned self] in
            self.performSegue(withIdentifier: self.unwindSegue!.rawValue, sender: nil)
        }
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Observation.
        NotificationCenter.default.addObserver(
            self, selector: #selector(entityWasUpdated(_:)),
            name: .EntityUpdateOperation, object: flowDataSource
        )
        // Traits.
        if dayDate == RecurringDate {
            isAddingEventEnabled = false
        }
        if isAddingEventEnabled && backgroundTapTrait == nil {
            backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
            backgroundTapTrait!.isBarButtonItemEnabled = !Settings.shouldHideAddButtons
        }
        // Title.
        if dayDate == RecurringDate {
            title = "Recurring in \(DateFormatter.monthFormatter.string(from: monthDate))"
        } else {
            title = DateFormatter.monthDayFormatter.string(from: dayDate)
        }
        title = title!.uppercased()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView!.updateBackgroundOnAppearance(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        collectionView!.updateBackgroundOnAppearance(animated: true, reverse: true)
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(
            alongsideTransition: { context in self.tileLayout.invalidateLayout() },
            completion: { context in self.backgroundTapTrait?.updateFallbackHitArea() }
        )
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        currentSegue = segue
        UIApplication.shared.sendAction(.prepareSegueForDescendant, from: self)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(dayDate, forKey: #keyPath(dayDate))
        coder.encode(monthDate, forKey: #keyPath(monthDate))
        coder.encode(events, forKey: #keyPath(events))
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        dayDate = coder.decodeObject(forKey: #keyPath(dayDate)) as! Date
        monthDate = coder.decodeObject(forKey: #keyPath(monthDate)) as! Date
        events = coder.decodeObject(forKey: #keyPath(events)) as! [Any]
        var observer: NSObjectProtocol!
        observer = NotificationCenter.default.addObserver(forName: .EntityFetchOperation, object: nil, queue: nil) { _ in
            self.updateData(andReload: true)
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()
        collectionView!.reloadData()
    }

    // MARK: Handlers

    @objc private func settingsDidChange(_ notification: Notification) {
        backgroundTapTrait?.isBarButtonItemEnabled = !Settings.shouldHideAddButtons
    }

    @objc private func entityWasUpdated(_ notification: Notification) {
        // NOTE: This will run even when this screen isn't visible.
        guard let payload = notification.userInfo?.notificationUserInfoPayload() as? EntityUpdatedPayload
            else { return }
        // TODO: Handle reloading for deletes.
        if let event = payload.event {
            let previousEvent = payload.presave.event
            if event.startDate.dayDate == dayDate {
                let didChangeOrder = event.startDate != previousEvent.startDate
                if didChangeOrder,
                    let monthsEvents = flowDataSource.events,
                    let events = monthsEvents.eventsForDay(of: dayDate) as? [Event],
                    let index = events.index(of: event) {
                    currentIndexPath = IndexPath(item: index, section: 0)
                }
            } else {
                currentIndexPath = nil
            }
        }

        updateData(andReload: true)
    }

    // MARK: Actions

    @IBAction private func prepareForUnwindSegue(_ sender: UIStoryboardSegue) {
        currentSegue = sender
        UIApplication.shared.sendAction(.prepareSegueForDescendant, from: self)
    }

    // MARK: Data

    private func updateData(andReload reload: Bool) {
        let monthsEvents = flowDataSource.events
        if dayDate != nil && dayDate == RecurringDate {
            events = monthsEvents?.eventsForMonth(of: monthDate)?.eventsForDay(of: dayDate) ?? []
        } else {
            events = monthsEvents?.eventsForDay(of: dayDate) ?? []
        }
        if reload {
            collectionView!.reloadData()
        }
        let isBeingDismissedTo = presentedViewController != nil
        if isBeingDismissedTo, events.count == 0 {
            dispatchAfter(1) {
                self.performSegue(withIdentifier: self.unwindSegue!.rawValue, sender: nil)
            }
        }
    }

}

// MARK: CollectionViewBackgroundTapTraitDelegate

extension DayViewController: CollectionViewBackgroundTapTraitDelegate {

    var backgroundFallbackHitAreaHeight: CGFloat { return topLayoutGuide.length }

    func backgroundTapTraitDidToggleHighlight(at location: CGPoint) {
        let identifier = Segue.addEvent.rawValue
        if self.shouldPerformSegue(withIdentifier: identifier, sender: nil) {
            self.performSegue(withIdentifier: identifier, sender: nil)
        }
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

extension DayViewController: CollectionViewDragDropDeletionTraitDelegate {

    func canDeleteCellOnDrop(cellFrame: CGRect) -> Bool {
        return tileLayout.canDeleteCellOnDrop(cellFrame: cellFrame)
    }

    func canDragCell(at cellIndexPath: IndexPath) -> Bool {
        guard flowDataSource is UpcomingEvents else { return false }
        guard cellIndexPath.row < events.count else { return false }
        return event(at: cellIndexPath.row).calendar.allowsContentModifications
    }

    func deleteDroppedCell(_ cell: UIView, completion: () -> Void) throws {
        let event = self.event(at: currentIndexPath!.item)
        try flowDataSource.remove(event: event, commit: true)
        currentIndexPath = nil
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
        tileLayout.isDeletionDropzoneHidden = true
    }

    func didStartDraggingCellForDeletion(at cellIndexPath: IndexPath) {
        currentIndexPath = cellIndexPath
        tileLayout.isDeletionDropzoneHidden = false
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension DayViewController: CollectionViewZoomTransitionTraitDelegate {

    func zoomTransition(_ transition: ZoomTransition,
                        subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView] {
        guard let cell = cell as? EventViewCell else { preconditionFailure() }
        return [cell.mainLabel, cell.detailsView]
    }

    func zoomTransition(_ transition: ZoomTransition,
                        subviewInDestinationViewController viewController: UIViewController,
                        forSubview subview: UIView) -> UIView? {
        let viewController = viewController as! EventViewController
        switch subview {
        case is UILabel: return viewController.descriptionView.superview
        case is EventDetailsView: return viewController.detailsView
        default: fatalError()
        }
    }

}

// MARK: - Data

extension DayViewController {

    fileprivate func event(at index: Int) -> Event {
        return DayEvents.event(at: index, of: events)!
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return events.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: EventViewCell.self), for: indexPath
        )
        if let cell = cell as? EventViewCell {
            cell.setUpAccessibility(at: indexPath)
            cell.delegate = self
            EventViewCell.render(cell: cell, fromEvent: events[indexPath.item])
        }
        return cell
    }

}

// MARK: - Event Cell

extension DayViewController {

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView,
                                 shouldSelectItemAt indexPath: IndexPath) -> Bool {
        currentIndexPath = indexPath
        return true
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didHighlightItemAt indexPath: IndexPath) {
        guard indexPath == currentIndexPath else { return }
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewTileCell
        cell.animateHighlighted(
            depressDepth: UIOffset(horizontal: 0, vertical: 2 / cell.frame.height)
        )
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewTileCell else { return }
        cell.animateUnhighlighted()
    }

}

// MARK: - Layout

// MARK: EventViewCellDelegate

extension DayViewController: EventViewCellDelegate {

    func eventViewCell(_ cell: EventViewCell, didToggleInstances visible: Bool) {
        guard let indexPath = collectionView!.indexPath(for: cell) else { return }
        if visible {
            tileLayout.expandedTiles.insert(indexPath)
        } else {
            tileLayout.expandedTiles.remove(indexPath)
        }
        collectionView!.performBatchUpdates(nil)
    }

}

// MARK: UICollectionViewDelegateFlowLayout

extension DayViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let event = self.event(at: indexPath.item)

        let cellSizes = EventViewCellSizes(sizeClass: traitCollection.horizontalSizeClass)
        var size = tileLayout.itemSize
        size.height = cellSizes.emptyCellHeight
        size.height += cellSizes.mainLabelLineHeight
        if event.startDate.hasCustomTime || event.hasLocation {
            size.height += cellSizes.detailsViewHeight
        }

        if tileLayout.expandedTiles.contains(indexPath) {
            size.height += 50
        }
        return size
    }

}
