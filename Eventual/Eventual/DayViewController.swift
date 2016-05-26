//
//  DayViewController.swift
//  Eventual
//
//  Copyright (c) 2014-present Eventual App. All rights reserved.
//

import UIKit
import EventKit

class DayViewController: UICollectionViewController, CoordinatedViewController {

    // MARK: State

    weak var delegate: ViewControllerDelegate!

    var currentIndexPath: NSIndexPath?

    // MARK: Add Event

    @IBOutlet private(set) var backgroundTapRecognizer: UITapGestureRecognizer!
    var backgroundTapTrait: CollectionViewBackgroundTapTrait!

    // MARK: Data Source

    var dayDate: NSDate!
    private var events: [Event]!
    private var eventManager: EventManager { return EventManager.defaultManager }

    // MARK: Layout

    private var tileLayout: CollectionViewTileLayout {
        return self.collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: Navigation

    private(set) var zoomTransitionTrait: CollectionViewZoomTransitionTrait!

    // MARK: Appearance

    private var appearanceManager: AppearanceManager { return AppearanceManager.defaultManager }

    // MARK: - Initializers

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setUp()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }

    deinit {
        self.tearDown()
    }

    private func setUp() {
        self.customizeNavigationItem()

        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(
            self, selector: #selector(MonthsViewController.applicationDidBecomeActive(_:)),
            name: UIApplicationDidBecomeActiveNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(DayViewController.entitySaveOperationDidComplete(_:)),
            name: EntitySaveOperationNotification, object: nil
        )

        self.installsStandardGestureForInteractiveMovement = true
    }
    private func tearDown() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAccessibilityLabels()
        // Data.
        self.updateData()
        // Title.
        self.title = NSDateFormatter.monthDayFormatter.stringFromDate(self.dayDate)
        self.customizeNavigationItem() // Hacky sync.
        // Transition.
        self.zoomTransitionTrait = CollectionViewZoomTransitionTrait(delegate: self)
        // Layout customization.
        self.tileLayout.dynamicNumberOfColumns = false
        self.tileLayout.registerNib(UINib(nibName: String(EventDeletionDropzoneView), bundle: NSBundle.mainBundle()),
                                    forDecorationViewOfKind: CollectionViewTileLayout.deletionViewKind)
        // Traits.
        self.backgroundTapTrait = CollectionViewBackgroundTapTrait(delegate: self)
        self.backgroundTapTrait.enabled = self.appearanceManager.minimalismEnabled
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.zoomTransitionTrait.isInteractionEnabled = true
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.backgroundTapTrait.updateOnAppearance(true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.backgroundTapTrait.updateOnAppearance(true, reverse: true)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.presentedViewController == nil {
            self.zoomTransitionTrait.isInteractionEnabled = false
        }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition(
            { context in self.tileLayout.invalidateLayout() },
            completion: nil
        )
    }

    private func setAccessibilityLabels() {
        self.collectionView!.accessibilityLabel = t(Label.DayEvents.rawValue)
    }

    // MARK: Handlers

    func applicationDidBecomeActive(notification: NSNotification) {
        // In case settings change.
        if let backgroundTapTrait = self.backgroundTapTrait {
            backgroundTapTrait.enabled = self.appearanceManager.minimalismEnabled
        }
    }

    func entitySaveOperationDidComplete(notification: NSNotification) {
        // NOTE: This will run even when this screen isn't visible.
        guard (notification.userInfo?[TypeKey] as? UInt) == EKEntityType.Event.rawValue else { return }
        self.updateData()
        self.collectionView!.reloadData()
    }
}

// MARK: - Navigation

extension DayViewController {

    // MARK: Actions

    @IBAction private func unwindToDay(sender: UIStoryboardSegue) {
        if
            let navigationController = self.presentedViewController as? NavigationViewController,
            let indexPath = self.currentIndexPath,
            let events = self.events
        {
            self.eventManager.updateEventsByMonthsAndDays() // FIXME
            self.updateData()
            self.collectionView!.reloadData()

            // Empty if moved to different day.
            var isCurrentEventInDay = !self.events.isEmpty
            if events.count > indexPath.item && events[indexPath.item].startDate.dayDate != self.dayDate {
                isCurrentEventInDay = false
            }
            if !isCurrentEventInDay {
                // Just do the default transition if the snapshotReferenceView is illegitimate.
                navigationController.transitioningDelegate = nil
                navigationController.modalPresentationStyle = .FullScreen
            }
        }
    }

    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        guard let rawIdentifier = segue.identifier, identifier = Segue(rawValue: rawIdentifier) else { return }
        switch identifier {

        case .AddEvent:
            self.currentIndexPath = nil // Reset.
            self.delegate.prepareAddEventSegue(segue)

        case .EditEvent:
            if sender is EventViewCell {
                self.zoomTransitionTrait.isInteractive = false
            }
            guard let indexPath = self.currentIndexPath, event = self.events?[indexPath.item] else { break }
            self.delegate.prepareEditEventSegue(segue, event: event)

        default: break
        }
    }

}

// MARK: CollectionViewBackgroundTapTraitDelegate

extension DayViewController: CollectionViewBackgroundTapTraitDelegate {

    func backgroundTapTraitDidToggleHighlight() {
        self.performSegueWithIdentifier(Segue.AddEvent.rawValue, sender: self.backgroundTapTrait)
    }

    func backgroundTapTraitFallbackBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(
            barButtonSystemItem: .Add,
            target: self, action: #selector(backgroundTapTraitDidToggleHighlight)
        )
    }

}

// MARK: CollectionViewZoomTransitionTraitDelegate

extension DayViewController: CollectionViewZoomTransitionTraitDelegate {

    func animatedTransition(transition: AnimatedTransition,
                            subviewsToAnimateSeparatelyForReferenceCell cell: CollectionViewTileCell) -> [UIView]
    {
        guard let cell = cell as? EventViewCell else { assertionFailure("Wrong cell."); return [] }
        return [cell.mainLabel, cell.detailsView]
    }

    func animatedTransition(transition: AnimatedTransition,
                            subviewInDestinationViewController viewController: UIViewController,
                            forSubview subview: UIView) -> UIView?
    {
        guard let viewController = viewController as? EventViewController else {
            assertionFailure("Wrong view controller.")
            return nil
        }
        switch subview {
        case is UILabel: return viewController.descriptionView.superview
        case is EventDetailsView: return viewController.detailsView
        default: assertionFailure("Unsupported source subview."); return nil
        }
    }

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
                                                withSnapshotReferenceCell cell: CollectionViewTileCell)
    {
        self.performSegueWithIdentifier(Segue.EditEvent.rawValue, sender: transition)
    }

}

// MARK: - Data

extension DayViewController {

    private func updateData() {
        self.events = (self.eventManager.monthsEvents?.eventsForDayOfDate(self.dayDate) ?? []) as! [Event]
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.events?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(EventViewCell), forIndexPath: indexPath)
        if let cell = cell as? EventViewCell {
            cell.setAccessibilityLabelsWithIndexPath(indexPath)

            if let event = self.events?[indexPath.item] {
                cell.eventText = event.title
                cell.detailsView.event = event
            }
        }
        return cell
    }

    override func collectionView(collectionView: UICollectionView,
                                 canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    override func collectionView(collectionView: UICollectionView,
                                 moveItemAtIndexPath sourceIndexPath: NSIndexPath,
                                 toIndexPath destinationIndexPath: NSIndexPath)
    {
        self.collectionView?.reloadData() // Cancel.
    }
}

// MARK: - Event Cell

extension DayViewController {

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        self.currentIndexPath = indexPath
        return true
    }

    override func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.guaranteedCellForItemAtIndexPath(indexPath) as? CollectionViewTileCell else { return }
        cell.animateHighlighted(
            depressDepth: UIOffset(horizontal: 0, vertical: 2 / cell.frame.height)
        )
    }

    override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.guaranteedCellForItemAtIndexPath(indexPath) as? CollectionViewTileCell else { return }
        cell.animateUnhighlighted()
    }

}

// MARK: - Layout

extension DayViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        var cellSizes = EventViewCellSizes(sizeClass: self.traitCollection.horizontalSizeClass)

        // NOTE: In case this screen ever needed multi-column support.
        var size = self.tileLayout.sizeForItemAtIndexPath(indexPath)
        size.height = cellSizes.emptyCellHeight

        if let event = self.events?[indexPath.item] {
            if event.startDate.hasCustomTime || event.hasLocation {
                size.height += cellSizes.detailsViewHeight
            }

            cellSizes.width = size.width
            let labelRect = EventViewCell.mainLabelTextRectForText(event.title, cellSizes: cellSizes)
            var labelHeight = floor(labelRect.size.height) // Avoid sub-pixel rendering.
            if labelHeight <= cellSizes.mainLabelMaxHeight && labelHeight > cellSizes.mainLabelLineHeight {
                labelHeight -= cellSizes.mainLabelLineHeight
            }
            let correctionRatio: CGFloat = 1.04 // Label height constants are rounded down for easier math.
            size.height += ceil(min(cellSizes.mainLabelMaxHeight, labelHeight) * correctionRatio)
        }

        return size
    }

}
