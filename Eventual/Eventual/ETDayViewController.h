//
//  ETDayViewController.h
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/13/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETDayViewController : UICollectionViewController

@property (nonatomic, strong) NSDate *dayDate;
@property (nonatomic, strong) NSArray *dayEvents;

@end
