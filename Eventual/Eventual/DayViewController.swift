//
//  DayViewController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import EventKit

class DayViewController: UICollectionViewController {

    // MARK: State

    private var currentIndexPath: NSIndexPath?

    // MARK: Add Event

    @IBOutlet private var backgroundTapRecognizer: UITapGestureRecognizer!
    var backgroundTapTrait: CollectionViewBackgroundTapTrait!

    // MARK: Data Source

    var dayDate: NSDate?

    private lazy var titleFormatter: NSDateFormatter! = {
        let titleFormatter = NSDateFormatter()
        titleFormatter.dateFormat = "MMMM d"
        return titleFormatter
    }()

    private var eventManager: EventManager { return EventManager.defaultManager }

    private var dayEvents: NSArray?
    var dataSource: NSArray? {
        get {
            if self.dayEvents == nil, let dayDate = self.dayDate {
                self.dayEvents = self.eventManager.eventsForDayDate(dayDate)
            }
            return self.dayEvents
        }
        set(newValue) {
            self.dayEvents = newValue
        }
    }

    var autoReloadDataTrait: CollectionViewAutoReloadDataTrait!

    // MARK: Layout

    private var tileLayout: CollectionViewTileLayout {
        return self.collectionViewLayout as! CollectionViewTileLayout
    }

    // MARK: Navigation

    private var customTransitioningDelegate: TransitioningDelegate!

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
    }
    private func tearDown() {
        NSNotificationCenter.defaultCenter().removeObserver(self.autoReloadDataTrait)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAccessibilityLabels()
        // Title.
        guard let dayDate = self.dayDate else { fatalError("Requires dayDate.") }
        self.title = self.titleFormatter.stringFromDate(dayDate)
        self.customizeNavigationItem() // Hacky sync.
        // Transition.
        self.customTransitioningDelegate = TransitioningDelegate(animationDelegate: self, interactionDelegate: self)
        // Layout customization.
        self.tileLayout.dynamicNumberOfColumns = false
        // Traits.
        self.backgroundTapTrait = CollectionViewBackgroundTapTrait(
            delegate: self,
            collectionView: self.collectionView!,
            tapRecognizer: self.backgroundTapRecognizer
        )
        self.autoReloadDataTrait = CollectionViewAutoReloadDataTrait(collectionView: self.collectionView!)
        NSNotificationCenter.defaultCenter().addObserver( self.autoReloadDataTrait,
            selector: Selector("reloadFromEntityOperationNotification:"),
            name: EntitySaveOperationNotification, object: nil
        )
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.customTransitioningDelegate.isInteractionEnabled = true
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.presentedViewController == nil {
            self.customTransitioningDelegate.isInteractionEnabled = false
        }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({ (context) in
            self.tileLayout.invalidateLayout()
        }, completion: nil)
    }

    private func setAccessibilityLabels() {
        self.collectionView!.accessibilityLabel = t(Label.DayEvents.rawValue)
    }

}

// MARK: - Navigation

extension DayViewController: TransitionAnimationDelegate, TransitionInteractionDelegate,
                             CollectionViewBackgroundTapTraitDelegate
{

    // MARK: Actions

    @IBAction private func unwindToDay(sender: UIStoryboardSegue) {
        if let indexPath = self.currentIndexPath,
               navigationController = self.presentedViewController as? NavigationController,
               event = self.dataSource?[indexPath.item] as? EKEvent
               where event.startDate != self.dayDate // Is date modified?
        {
            // Just do the default transition if the snapshotReferenceView is illegitimate.
            self.invalidateDataSource()
            navigationController.transitioningDelegate = nil
            navigationController.modalPresentationStyle = .FullScreen
        }
    }

    // MARK: CollectionViewBackgroundTapTraitDelegate

    func backgroundTapTraitDidToggleHighlight() {
        self.performSegueWithIdentifier(Segue.AddEvent.rawValue, sender: self.backgroundTapTrait)
    }

    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        guard let rawIdentifier = segue.identifier,
                  identifier = Segue(rawValue: rawIdentifier),
                  navigationController = segue.destinationViewController as? NavigationController,
                  viewController = navigationController.topViewController as? EventViewController
              else { return }

        switch identifier {

        case .AddEvent:
            self.currentIndexPath = nil // Reset.

            let event = EKEvent(eventStore: self.eventManager.store)
            event.title = ""
            if let dayDate = self.dayDate {
                event.startDate = dayDate
            }
            viewController.event = event
            if let dayDate = self.dayDate {
                viewController.newEventStartDate = dayDate
            }
            viewController.unwindSegueIdentifier = .UnwindToDay

        case .EditEvent:
            navigationController.transitioningDelegate = self.customTransitioningDelegate
            navigationController.modalPresentationStyle = .Custom
            if sender is EventViewCell {
                self.customTransitioningDelegate.isInteractive = false
            }

            guard let indexPath = self.currentIndexPath else { break }
            if let event = self.dataSource?[indexPath.item] as? EKEvent {
                viewController.event = event
            }
            viewController.unwindSegueIdentifier = .UnwindToDay

        default: assertionFailure("Unsupported segue \(identifier).")
        }
    }

    // MARK: TransitionAnimationDelegate

    func animatedTransition(transition: AnimatedTransition,
         snapshotReferenceViewWhenReversed reversed: Bool) -> UIView
    {
        guard let indexPath = self.currentIndexPath else { return self.collectionView! }
        return self.collectionView!.guaranteedCellForItemAtIndexPath(indexPath)
    }

    func animatedTransition(transition: AnimatedTransition,
         willCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)
    {
        guard let cell = snapshotReferenceView as? CollectionViewTileCell else { return }
        cell.showAllBorders()
    }

    func animatedTransition(transition: AnimatedTransition,
         didCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)
    {
        guard let cell = snapshotReferenceView as? CollectionViewTileCell else { return }
        cell.restoreOriginalBordersIfNeeded()
    }

    // MARK: TransitionInteractionDelegate

    func interactiveTransition(transition: InteractiveTransition,
         windowForGestureRecognizer recognizer: UIGestureRecognizer) -> UIWindow
    {
        return UIApplication.sharedApplication().keyWindow!
    }

    func interactiveTransition(transition: InteractiveTransition,
         locationContextViewForGestureRecognizer recognizer: UIGestureRecognizer) -> UIView
    {
        return self.collectionView!
    }

    func interactiveTransition(transition: InteractiveTransition,
         snapshotReferenceViewAtLocation location: CGPoint, ofContextView contextView: UIView) -> UIView?
    {
        guard let indexPath = self.collectionView!.indexPathForItemAtPoint(location) else { return nil }
        return self.collectionView!.guaranteedCellForItemAtIndexPath(indexPath)
    }

    func beginInteractivePresentationTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)
    {
        if let cell = referenceView as? EventViewCell,
               indexPath = self.collectionView!.indexPathForCell(cell)
        {
            self.currentIndexPath = indexPath
            self.performSegueWithIdentifier(Segue.EditEvent.rawValue, sender: transition)
        }
    }

    func beginInteractiveDismissalTransition(transition: InteractiveTransition,
         withSnapshotReferenceView referenceView: UIView?)
    {
        if let customTransitioningDelegate = self.navigationController?.transitioningDelegate as? TransitioningDelegate {
            customTransitioningDelegate.isInteractive = true
            print("DEBUG")
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func interactiveTransition(transition: InteractiveTransition,
         destinationScaleForSnapshotReferenceView referenceView: UIView?,
         contextView: UIView, reversed: Bool) -> CGFloat
    {
        guard let referenceView = referenceView else { return -1.0 }
        return contextView.frame.size.height / (referenceView.frame.size.height * 2.0)
    }

}

// MARK: - Data

extension DayViewController {

    private func invalidateDataSource() {
        self.eventManager.updateEventsByMonthsAndDays()
        self.dataSource = nil
        self.collectionView!.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var number = 0
        if let dataSource = self.dataSource {
            number = dataSource.count
        }
        return number
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(EventViewCell.reuseIdentifier, forIndexPath: indexPath)
        if let cell = cell as? EventViewCell {
            cell.setAccessibilityLabelsWithIndexPath(indexPath)
        }
        if let cell = cell as? EventViewCell,
               event = self.dataSource?[indexPath.item] as? EKEvent
        {
            cell.eventText = event.title
            cell.detailsView.event = event
        }
        return cell
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
        cell.animateHighlighted()
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
        // NOTE: In case this screen ever needed multi-column support.
        var size = self.tileLayout.sizeForItemAtIndexPath(indexPath)

        size.height = EventViewCell.emptyCellHeight
        if let event = self.dataSource?[indexPath.item] as? EKEvent {
            if event.startDate.hasCustomTime || event.hasLocation {
                size.height += EventViewCell.detailsViewHeight
            }

            let labelRect = EventViewCell.mainLabelTextRectForText(event.title, cellWidth: size.width)
            var labelHeight = floor(labelRect.size.height) // Avoid sub-pixel rendering.
            if labelHeight <= EventViewCell.mainLabelMaxHeight && labelHeight > EventViewCell.mainLabelLineHeight {
                labelHeight -= EventViewCell.mainLabelLineHeight
            }
            let correctionRatio: CGFloat = 1.04 // Label height constants are rounded down for easier math.
            size.height += ceil(min(EventViewCell.mainLabelMaxHeight, labelHeight) * correctionRatio)
        }

        return size
    }

}
