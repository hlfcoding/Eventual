//
//  ETDayViewCell.h
//  Eventual
//
//  Created by Nest Master on 11/5/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETDayViewCell : UICollectionViewCell

@property (nonatomic, readonly, getter = defaultBorderInsets) UIEdgeInsets defaultBorderInsets;
@property (nonatomic, setter = setBorderInsets:) UIEdgeInsets borderInsets;

@property (nonatomic, setter = setDayText:) NSString *dayText;
@property (nonatomic, setter = setIsToday:) BOOL isToday;
@property (nonatomic, setter = setNumberOfEvents:) NSUInteger numberOfEvents;

@property (nonatomic, weak, readonly) UIView *innerContentView;

- (void)setAccessibilityLabelsWithIndexPath:(NSIndexPath *)indexPath;

@end
