//
//  ETDayViewCell.h
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/5/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETDayViewCell : UICollectionViewCell

<UIAppearance>

@property (nonatomic, readonly, getter = defaultBorderInsets) UIEdgeInsets defaultBorderInsets;
@property (nonatomic, setter = setBorderInsets:) UIEdgeInsets borderInsets;

@property (nonatomic, setter = setDayText:) NSString *dayText;
@property (nonatomic, setter = setIsToday:) BOOL isToday;
@property (nonatomic, setter = setNumberOfEvents:) NSUInteger numberOfEvents;

@property (nonatomic, strong) NSNumber *popAnimationDuration UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSNumber *popAnimationScale UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSNumber *popAnimationSpringDamping UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSNumber *popAnimationSpringInitialVelocity UI_APPEARANCE_SELECTOR;

@property (nonatomic, weak, readonly) UIView *innerContentView;

- (void)setAccessibilityLabelsWithIndexPath:(NSIndexPath *)indexPath;

- (void)performPopAnimationWithCompletion:(void (^)(BOOL finished))completion;

@end
