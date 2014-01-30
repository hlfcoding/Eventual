//
//  ETTransitionManager.h
//  Eventual
//
//  Created by Nest Master on 1/29/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ETTransitionAnimation) {
  ETTransitionAnimationNone,
  ETTransitionAnimationZoom
};

@interface ETTransitionManager : NSObject

<UIViewControllerTransitioningDelegate, UIViewControllerTransitionCoordinator, UIViewControllerTransitionCoordinatorContext,
UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

@property (weak, nonatomic) UIView *currentZoomedOutView;
@property (nonatomic) CGRect currentZoomedOutFrame;

@property (nonatomic) ETTransitionAnimation currentAnimation;
@property (nonatomic) BOOL currentlyIsReversed;

@end
