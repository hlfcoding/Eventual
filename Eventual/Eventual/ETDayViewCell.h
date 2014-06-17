//
//  ETDayViewCell.h
//  Eventual
//
//  Created by Nest Master on 11/5/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETDayViewCell : UICollectionViewCell

@property (nonatomic, setter = setDayText:) NSString *dayText;
@property (nonatomic, setter = setIsToday:) BOOL isToday;
@property (nonatomic, setter = setNumberOfEvents:) NSUInteger numberOfEvents;

- (void)setAccessibilityLabelsWithIndexPath:(NSIndexPath *)indexPath;

@end
