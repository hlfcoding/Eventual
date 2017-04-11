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

    weak var coordinator: NavigationCoordinatorProtocol?
    weak var currentSegue: UIStoryboardSegue?
    var unwindSegue: Segue?

    func finishRestoringState() {
        updateData(andReload: true)
    }

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
            self, selector: #selector(applicationDidBecomeActive(notification:)),
            name: .UIApplicationDidBecomeActive, object: nil
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
        // Data.
        updateData(andReload: false)
        // Layout customization.
        tileLayout.completeSetUp()
        tileLayout.dynamicNumberOfColumns = false
        // Traits.
        deletionTrait = CollectionViewDragDropDeletionTrait(delegate: self)
        swipeDismissalTrait = ViewControllerSwipeDismissalTrait(viewController: self) { [unowned self] in
            self.performSegue(withIdentifier: self.unwindSegue!.rawValue, sender: nil)
        }
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Traits.
        if dayDate == RecurringDate {
            isAddingEventEnabled = false
        }
        if isAddingEventEnabled && backgroundTapTrait == nil {
            backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
            backgroundTapTrait!.isEnabled = Appearance.shouldTapToAddEvent
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
        UIApplication.shared.sendAction(Selector(("prepareSegue:")), to: nil, from: self, for: nil)
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
        let coordinator = AppDelegate.sharedDelegate.mainCoordinator
        coordinator.pushRestoringScreen(self)
        self.coordinator = coordinator
    }

    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()
        collectionView!.reloadData()
    }

    // MARK: Handlers

    func applicationDidBecomeActive(notification: Notification) {
        // In case settings change.
        backgroundTapTrait?.isEnabled = Appearance.shouldTapToAddEvent
    }

    func entityUpdateOperationDidComplete(notification: Notification) {
        // NOTE: This will run even when this screen isn't visible.
        guard let payload = notification.userInfo?.notificationUserInfoPayload() as? EntityUpdatedPayload
            else { return }
        // TODO: Handle reloading for deletes.
        if let event = payload.event {
            let previousEvent = payload.presave.event
            if event.startDate.dayDate == dayDate {
                let didChangeOrder = event.startDate != previousEvent.startDate
                if didChangeOrder,
                    let events = coordinator?.monthsEvents?.eventsForDay(of: dayDate) as? [Event],
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
        UIApplication.shared.sendAction(Selector(("prepareSegue:")), to: nil, from: self, for: nil)
    }

    // MARK: Data

    private func updateData(andReload reload: Bool) {
        if dayDate != nil && dayDate == RecurringDate {
            events = coordinator?.monthsEvents?
                .eventsForMonth(of: monthDate)?.eventsForDay(of: dayDate) ?? []
        } else {
            events = coordinator?.monthsEvents?.eventsForDay(of: dayDate) ?? []
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
        guard cellIndexPath.row < events.count else { return false }
        return event(at: cellIndexPath.row).calendar.allowsContentModifications
    }

    func deleteDroppedCell(_ cell: UIView, completion: () -> Void) throws {
        guard let coordinator = coordinator, let indexPath = currentIndexPath
            else { preconditionFailure() }
        let event = self.event(at: indexPath.item)
        try coordinator.remove(event: event)
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
        guard let viewController = viewController as? EventViewController
            else { preconditionFailure("Wrong view controller.") }
        switch subview {
        case is UILabel: return viewController.descriptionView.superview
        case is EventDetailsView: return viewController.detailsView
        default: fatalError("Unsupported source subview.")
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
