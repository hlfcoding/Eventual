//
//  ETDayViewController.h
//  Eventual
//
//  Created by Nest Master on 11/13/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETDayViewController : UICollectionViewController

@property (strong, nonatomic) NSDate *dayDate;
@property (strong, nonatomic) NSArray *dayEvents;

@end