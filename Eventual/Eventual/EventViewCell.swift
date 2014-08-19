//
//  EventViewCell.swift
//  Eventual
//
//  Created by Peng Wang on 8/16/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

import UIKit

@objc(ETEventViewCell) class EventViewCell: UICollectionViewCell {
    
    var eventText: String? {
        didSet {
            if self.eventText == oldValue { return }
            self.mainLabel.text = self.eventText
        }
    }
    
    @IBOutlet private var mainLabel: UILabel!
    
    override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
}
