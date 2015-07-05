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
    var interactiveBackgroundViewTrait: CollectionViewInteractiveBackgroundViewTrait!
    
    // MARK: Data Source

    var dayDate: NSDate?
    
    private lazy var titleFormatter: NSDateFormatter! = {
        let titleFormatter = NSDateFormatter()
        titleFormatter.dateFormat = "MMMM d"
        return titleFormatter
    }()

    private lazy var eventManager: EventManager! = {
        return EventManager.defaultManager()
    }()
    
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
    
    private let CellReuseIdentifier = "Event"
    
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
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }
    
    deinit {
        self.tearDown()
    }
    
    private func setUp() {}
    private func tearDown() {
        NSNotificationCenter.defaultCenter().removeObserver(self.autoReloadDataTrait)
    }

    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAccessibilityLabels()
        // Title.
        if let dayDate = self.dayDate {
            self.title = self.titleFormatter.stringFromDate(dayDate)
        }
        // Transition.
        self.customTransitioningDelegate = TransitioningDelegate(animationDelegate: self, interactionDelegate: self)
        // Layout customization.
        self.tileLayout.dynamicNumberOfColumns = false
        // Traits.
        self.interactiveBackgroundViewTrait = CollectionViewInteractiveBackgroundViewTrait(
            collectionView: self.collectionView!,
            tapRecognizer: self.backgroundTapRecognizer
        )
        self.interactiveBackgroundViewTrait.setUp()
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
        dispatch_async(dispatch_get_main_queue()) {
            self.tileLayout.invalidateLayout()
        }
    }

    private func setAccessibilityLabels() {
        self.collectionView!.isAccessibilityElement = true
        self.collectionView!.accessibilityLabel = t(Label.DayEvents.rawValue)
    }

}

// MARK: - Navigation

extension DayViewController: TransitionAnimationDelegate, TransitionInteractionDelegate {

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
        self.customTransitioningDelegate.isInteractive = false
        /*
        Unfortunately, because this view controller's also presented modally, dismissing its modal
        dismisses all the way up the modal 'stack'. This is stock iOS behavior that's difficult to
        avoid. One solution is to rework all transitions and the view controller structure to
        support push segues, but that requires removing navigation controllers (work) and replacing
        custom modal transitions (lame) with locked, stock push transitions. Overall, this is more
        to do with painfully reaching UIKit's limits.
        */
        self.dismissViewControllerAnimated(true, completion: {
            self.customTransitioningDelegate.isInteractive = true
        })
    }

    @IBAction private func requestAddingEvent(sender: UITapGestureRecognizer) {
        dispatch_after(0.1) {
            self.interactiveBackgroundViewTrait.toggleHighlighted(false)
            self.performSegueWithIdentifier(Segue.AddEvent.rawValue, sender: sender)
        }
    }

    // MARK: UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get view controllers.
        if let navigationController = segue.destinationViewController as? NavigationController,
               viewController = navigationController.topViewController as? EventViewController,
               rawIdentifier = segue.identifier,
               identifier = Segue(rawValue: rawIdentifier)
        {
            // Prepare.
            if case identifier = Segue.AddEvent {
                self.currentIndexPath = nil // Reset.
                let event = EKEvent(eventStore: EventManager.defaultManager()!.store)
                event.title = ""
                if let dayDate = self.dayDate {
                    event.startDate = dayDate
                }
                viewController.event = event
            } else if case identifier = Segue.EditEvent,
                      let indexPath = self.currentIndexPath
            {
                navigationController.transitioningDelegate = self.customTransitioningDelegate
                navigationController.modalPresentationStyle = .Custom
                if let event = self.dataSource?[indexPath.item] as? EKEvent {
                    viewController.event = event
                }
                if sender is EventViewCell {
                    self.customTransitioningDelegate.isInteractive = false
                }
            }
        }
        super.prepareForSegue(segue, sender: sender)
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
        if let cell = snapshotReferenceView as? CollectionViewTileCell {
            self.tileLayout.restoreBordersToTileCellForSnapshot(cell)
        }
    }

    func animatedTransition(transition: AnimatedTransition,
         didCreateSnapshotViewFromSnapshotReferenceView snapshotReferenceView: UIView)
    {
        if let cell = snapshotReferenceView as? CollectionViewTileCell {
            self.tileLayout.restoreOriginalBordersToTileCell(cell)
        }
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

// MARK: - Add Event

extension DayViewController: UIGestureRecognizerDelegate {

    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer === self.backgroundTapRecognizer {
            self.interactiveBackgroundViewTrait.handleTap()
            //NSLog("Begin possible background tap.")
        }
        return true
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>)
    {
        self.interactiveBackgroundViewTrait
            .handleScrollViewWillEndDragging(scrollView, withVelocity: velocity,
                targetContentOffset: targetContentOffset)
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellReuseIdentifier, forIndexPath: indexPath)
        if let cell = cell as? EventViewCell {
            cell.setAccessibilityLabelsWithIndexPath(indexPath)
        }
        if let cell = cell as? EventViewCell,
               event = self.dataSource?[indexPath.item] as? EKEvent
        {
            cell.eventText = event.title
        }
        return cell
    }
    
}

// MARK: - Event Cell

extension DayViewController {

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        self.currentIndexPath = indexPath
        return true
    }
    
}

// MARK: - Layout

extension DayViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
         sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let width = self.tileLayout.itemSize.width
        var height: CGFloat = 75.0
        if let event = self.dataSource?[indexPath.item] as? EKEvent {
            let lineHeight = 23.0
            let maxRowCount = 3.0
            let ptPerChar = 300.0 / 35.0
            let charPerRow = Double(width) / ptPerChar
            let charCount = Double(event.title.characters.count)
            let rowCount = min(floor(charCount / charPerRow), maxRowCount)
            height += CGFloat(rowCount * lineHeight)
        }
        return CGSize(width: width, height: height)
    }
    
}