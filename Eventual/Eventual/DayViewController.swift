//
//  DayViewController.swift
//  Eventual
//
//  Created by Peng Wang on 7/23/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit
import EventKit

@objc(ETDayViewController) class DayViewController: UICollectionViewController {
    
    var dayDate: NSDate?
    
    private lazy var titleFormatter: NSDateFormatter! = {
        let titleFormatter = NSDateFormatter()
        titleFormatter.dateFormat = "MMMM d"
        return titleFormatter
    }()

    // MARK: Add Event

    @IBOutlet var backgroundTapRecognizer: UITapGestureRecognizer!
    var interactiveBackgroundViewTrait: CollectionViewInteractiveBackgroundViewTrait!
    
    // MARK: Data Source
    
    var dayEvents: NSArray?
    
    private let CellReuseIdentifier = "Event"
    private var dataSource: NSArray? { return self.dayEvents }
    
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
    private func tearDown() {}

    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAccessibilityLabels()
        self.interactiveBackgroundViewTrait = CollectionViewInteractiveBackgroundViewTrait(
            collectionView: self.collectionView!,
            tapRecognizer: self.backgroundTapRecognizer
        )
        self.interactiveBackgroundViewTrait.setUp()
        if let dayDate = self.dayDate {
            self.title = self.titleFormatter.stringFromDate(dayDate)
        }
    }
    
    private func setAccessibilityLabels() {
        self.collectionView!.isAccessibilityElement = true;
        self.collectionView!.accessibilityLabel = t(ETLabel.DayEvents.toRaw());
    }
}

// MARK: - Add Event

extension DayViewController: UIGestureRecognizerDelegate, UIScrollViewDelegate {

    @IBAction private func requestAddingEvent(sender: AnyObject?) {
        if let recognizer = sender as? UITapGestureRecognizer {
            if recognizer === self.backgroundTapRecognizer {
                //NSLog("Background tap.")
                dispatch_after(0.1) {
                    self.interactiveBackgroundViewTrait.toggleHighlighted(false)
                    self.performSegueWithIdentifier(ETSegue.AddDay.toRaw(), sender: sender)
                }
            }
        }
    }
    
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

// MARK: - Layout

extension DayViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
         sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let width = self.collectionView!.frame.size.width
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


