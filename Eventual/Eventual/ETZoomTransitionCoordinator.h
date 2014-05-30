//
//  ETTransitionManager.h
//  Eventual
//
//  Created by Nest Master on 1/29/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETZoomTransitionCoordinator : NSObject

<UIViewControllerTransitioningDelegate, UIViewControllerTransitionCoordinator, UIViewControllerTransitionCoordinatorContext,
UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

@property (nonatomic, weak) UIView *zoomContainerView;
@property (nonatomic, weak) UIView *zoomedOutView;
@property (nonatomic) CGRect zoomedOutFrame;

@property (nonatomic) NSTimeInterval zoomDuration;
@property (nonatomic) UIViewAnimationCurve zoomCompletionCurve;
@property (nonatomic, getter = isZoomReversed) BOOL zoomReversed;
@property (nonatomic, getter = isZoomInteractive) BOOL zoomInteractive;

@end
