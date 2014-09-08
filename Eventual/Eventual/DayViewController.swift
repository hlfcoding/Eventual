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
    
    // MARK: Data Source
    
    var dayEvents: NSArray?
    
    private let CellReuseIdentifier = "Event"
    private var dataSource: NSArray? { return self.dayEvents }
    
    // MARK: - Initializers
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
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
        if let dayDate = self.dayDate {
            self.title = self.titleFormatter.stringFromDate(dayDate)
        }
    }
    
    private func setAccessibilityLabels() {
        self.collectionView!.isAccessibilityElement = true;
        self.collectionView!.accessibilityLabel = NSLocalizedString(ETLabel.DayEvents.toRaw(), comment: "");
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
        if let dataSource = self.dataSource {
            if let event = dataSource[indexPath.item] as? EKEvent {
                cell.eventText = event.title
            }
        }
        return cell
    }
    
}

// MARK: - Layout

extension DayViewController: UICollectionViewDelegateFlowLayout {

    // TODO: Move into layout subclass.
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
         minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 1.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
         minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 1.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
         sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return CGSize(width: self.collectionView!.frame.size.width, height: 75.0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
         insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsetsZero
    }
    
}


