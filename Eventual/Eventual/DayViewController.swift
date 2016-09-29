//
//  DayViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

final class DayViewController: UICollectionViewController, DayScreen {

    // MARK: DayScreen

    weak var coordinator: NavigationCoordinatorProtocol?

    var currentIndexPath: IndexPath?
    var currentSelectedEvent: Event?
    var dayDate: Date!

    var isCurrentItemRemoved: Bool {
        guard let indexPath = currentIndexPath, let events = events, events.count > indexPath.item,
            let event = currentSelectedEvent
            else { return true }

        return event.startDate.dayDate != dayDate
    }

    var selectedEvent: Event? {
        guard let indexPath = currentIndexPath, let events = events, events.count > indexPath.item
            else { return nil }

        return events[indexPath.item]
    }

    var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: Data Source

    fileprivate var events: [Event]!

    // MARK: Interaction

    @IBOutlet private(set) var backgroundTapRecognizer: UITapGestureRecognizer!
    var backgroundTapTrait: CollectionViewBackgroundTapTrait!

    var deletionTrait: CollectionViewDragDropDeletionTrait!
    
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
        customizeNavigationItem()

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
        // Title.
        title = DateFormatter.monthDayFormatter.string(from: dayDate)
        customizeNavigationItem() // Hacky sync.
        // Layout customization.
        tileLayout.dynamicNumberOfColumns = false
        tileLayout.register(UINib(nibName: String(describing: EventDeletionDropzoneView.self), bundle: Bundle.main),
                            forDecorationViewOfKind: CollectionViewTileLayout.deletionViewKind)
        // Traits.
        backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
        backgroundTapTrait.isEnabled = Appearance.isMinimalismEnabled
        deletionTrait = CollectionViewDragDropDeletionTrait(delegate: self)
        zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        backgroundTapTrait.updateOnAppearance(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        backgroundTapTrait.updateOnAppearance(animated: true, reverse: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(
            alongsideTransition: { context in self.tileLayout.invalidateLayout() },
            completion: { context in self.backgroundTapTrait.updateFallbackHitArea() }
        )
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        coordinator?.prepare(for: segue, sender: sender)
    }

    // MARK: Handlers

    func applicationDidBecomeActive(notification: Notification) {
        // In case settings change.
        if let backgroundTapTrait = backgroundTapTrait {
            backgroundTapTrait.isEnabled = Appearance.isMinimalismEnabled
        }
    }

    func entityUpdateOperationDidComplete(notification: Notification) {
        // NOTE: This will run even when this screen isn't visible.
        guard let payload = notification.userInfo?.notificationUserInfoPayload() as? EntityUpdatedPayload
            else { return }
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
        coordinator?.prepare(for: sender, sender: nil)
    }

    // MARK: Data

    private func updateData(andReload reload: Bool) {
        events = (coordinator?.monthsEvents?.eventsForDay(of: dayDate) ?? []) as! [Event]
        if reload {
            collectionView!.reloadData()
        }
    }

}

// MARK: CollectionViewBackgroundTapTraitDelegate

extension DayViewController: CollectionViewBackgroundTapTraitDelegate {

    var backgroundFallbackHitAreaHeight: CGFloat { return tileLayout.viewportYOffset }

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

extension DayViewController: CollectionViewDragDropDeletionTraitDelegate {

    func canDeleteCellOnDrop(cellFrame: CGRect) -> Bool {
        return tileLayout.deletionDropZoneAttributes?.frame.intersects(cellFrame) ?? false
    }

    func canDragCell(cellIndexPath: IndexPath) -> Bool {
        guard cellIndexPath.row < events.count else { return false }
        return events[cellIndexPath.row].calendar.allowsContentModifications
    }

    func deleteDroppedCell(_ cell: UIView, completion: () -> Void) throws {
        guard let coordinator = coordinator, let indexPath = currentIndexPath,
            let event = events?[indexPath.item]
            else { preconditionFailure() }
        try coordinator.remove(event: event)
        currentIndexPath = nil
        completion()
    }

    func finalFrameForDroppedCell() -> CGRect {
        guard let dropZoneAttributes = tileLayout.deletionDropZoneAttributes else { preconditionFailure() }
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
        tileLayout.deletionDropZoneHidden = true
    }

    func willStartDraggingCellForDeletion(at cellIndexPath: IndexPath) {
        currentIndexPath = cellIndexPath
        tileLayout.deletionDropZoneHidden = false
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension DayViewController: CollectionViewZoomTransitionTraitDelegate {

    func animatedTransition(_ transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView] {
        guard let cell = cell as? EventViewCell else { preconditionFailure("Wrong cell.") }
        return [cell.mainLabel, cell.detailsView]
    }

    func animatedTransition(_ transition: AnimatedTransition,
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

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return events?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: EventViewCell.self), for: indexPath
        )
        if let cell = cell as? EventViewCell {
            cell.setUpAccessibility(at: indexPath)

            if let event = events?[indexPath.item] {
                EventViewCell.render(cell: cell, fromEvent: event)
            }
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
        guard let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewTileCell,
            indexPath == currentIndexPath
            else { return }
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

extension DayViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSizes = EventViewCellSizes(sizeClass: traitCollection.horizontalSizeClass)

        // NOTE: In case this screen ever needed multi-column support.
        var size = tileLayout.sizeForItem(at: indexPath)
        size.height = cellSizes.emptyCellHeight

        if let event = events?[indexPath.item] {
            if event.startDate.hasCustomTime || event.hasLocation {
                size.height += cellSizes.detailsViewHeight
            }

            size.height += cellSizes.mainLabelLineHeight
        }

        return size
    }

}
