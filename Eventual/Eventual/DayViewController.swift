//
//  DayViewController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Eventual App. All rights reserved.
//

import UIKit
import EventKit

@objc(ETDayViewController) class DayViewController: UICollectionViewController {
    
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

    private var dataSource: NSArray? {
        if let dayDate = self.dayDate {
            return self.eventManager.eventsForDayDate(dayDate)
        }
        return nil
    }
    
    private let CellReuseIdentifier = "Event"
    
    var autoReloadDataTrait: CollectionViewAutoReloadDataTrait!
    
    // MARK: Layout
    
    private var tileLayout: CollectionViewTileLayout {
        return self.collectionViewLayout as CollectionViewTileLayout
    }
    
    // MARK: Navigation
    
    private lazy var transitionCoordinator: ZoomTransitionCoordinator! = {
        var transitionCoordinator = ZoomTransitionCoordinator()
        transitionCoordinator.delegate = self.tileLayout
        return transitionCoordinator
    }()

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
        // Traits.
        self.interactiveBackgroundViewTrait = CollectionViewInteractiveBackgroundViewTrait(
            collectionView: self.collectionView!,
            tapRecognizer: self.backgroundTapRecognizer
        )
        self.interactiveBackgroundViewTrait.setUp()
        self.autoReloadDataTrait = CollectionViewAutoReloadDataTrait(collectionView: self.collectionView!)
        NSNotificationCenter.defaultCenter().addObserver( self.autoReloadDataTrait,
            selector: Selector("reloadFromEntityOperationNotification:"),
            name: ETEntitySaveOperationNotification, object: nil
        )
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        dispatch_async(dispatch_get_main_queue()) {
            self.tileLayout.invalidateLayout()
        }
    }
    
    private func setAccessibilityLabels() {
        self.collectionView!.isAccessibilityElement = true
        self.collectionView!.accessibilityLabel = t(ETLabel.DayEvents.rawValue)
    }

}

// MARK: - Navigation

extension DayViewController {

    private func setUpTransitionForCellAtIndexPath(indexPath: NSIndexPath) {
        let coordinator = self.transitionCoordinator
        let offset = self.collectionView!.contentOffset
        coordinator.zoomContainerView = self.navigationController!.view
        if let cell = self.collectionView!.cellForItemAtIndexPath(indexPath) as? EventViewCell {
            if let eventViewController = self.navigationController?.visibleViewController as? EventViewController {
                coordinator.zoomedInFrame = eventViewController.descriptionViewFrame
            }
            coordinator.zoomedOutView = cell
            coordinator.zoomedOutFrame = CGRectOffset(cell.frame, -offset.x, -offset.y)
        }
    }
    
    // MARK: Actions

    @IBAction private func dismissEventViewController(sender: UIStoryboardSegue) {
        if let indexPath = self.currentIndexPath {
            self.setUpTransitionForCellAtIndexPath(indexPath)
            self.transitionCoordinator.isZoomReversed = true
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    @IBAction private func requestAddingEvent(sender: AnyObject?) {
        if let recognizer = sender as? UITapGestureRecognizer {
            if recognizer === self.backgroundTapRecognizer {
                //NSLog("Background tap.")
                dispatch_after(0.1) {
                    self.interactiveBackgroundViewTrait.toggleHighlighted(false)
                    self.performSegueWithIdentifier(ETSegue.AddDay.rawValue, sender: sender)
                }
            }
        }
    }
    
    // MARK: UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        // Get view controllers.
        if !(segue.destinationViewController is NavigationController) { return }
        let navigationController = segue.destinationViewController as NavigationController
        if !(navigationController.viewControllers.first is EventViewController) { return }
        let viewController = navigationController.viewControllers.first as EventViewController
        // Prepare.
        switch segue.identifier! {
        case ETSegue.AddDay.rawValue:
            self.currentIndexPath = nil // Reset.
            var event = EKEvent(eventStore: EventManager.defaultManager().store)
            event.startDate = self.dayDate!
            event.title = ""
            viewController.event = event
            
        case ETSegue.EditDay.rawValue:
            if self.currentIndexPath != nil {
                self.setUpTransitionForCellAtIndexPath(self.currentIndexPath!)
                navigationController.transitioningDelegate = self.transitionCoordinator
                navigationController.modalPresentationStyle = .Custom
                if let viewController = navigationController.viewControllers[0] as? EventViewController {
                    viewController.event = self.dataSource?[self.currentIndexPath!.item] as EKEvent
                }
            }
        default: break
        }
    }
    
}

// MARK: - Add Event

extension DayViewController: UIGestureRecognizerDelegate, UIScrollViewDelegate {

    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldReceiveTouch touch: UITouch!) -> Bool {
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

extension DayViewController: UICollectionViewDataSource {
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var number = 0
        if let dataSource = self.dataSource {
            number = dataSource.count
        }
        return number
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellReuseIdentifier, forIndexPath: indexPath) as EventViewCell
        if let event = self.dataSource?[indexPath.item] as? EKEvent {
            cell.eventText = event.title
        }
        return cell
    }
    
}

// MARK: - Event Cell

extension DayViewController: UICollectionViewDelegate {
    
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
            let charCount = Double(countElements(event.title))
            let rowCount = min(floor(charCount / charPerRow), maxRowCount)
            height += CGFloat(rowCount * lineHeight)
        }
        return CGSize(width: width, height: height)
    }
    
}