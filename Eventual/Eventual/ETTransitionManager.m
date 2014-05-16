//
//  ETTransitionManager.m
//  Eventual
//
//  Created by Nest Master on 1/29/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

#import "ETTransitionManager.h"

#import "ETAppDelegate.h"
#import "ETDayViewController.h"
#import "ETEventViewController.h"
#import "ETMonthsViewController.h"

// TODO: Sometimes transition gets stuck.

@interface ETTransitionManager ()

@property (weak, nonatomic) UIViewController *currentDismissedViewController;
@property (weak, nonatomic) UIViewController *currentPresentedViewController;
@property (weak, nonatomic) UIViewController *currentPresentingViewController;
@property (weak, nonatomic) UIViewController *currentSourceViewController;
@property (weak, nonatomic) id<UIViewControllerContextTransitioning> currentTransitionContext;

@property (nonatomic) BOOL isLocked;
@property (nonatomic) UIModalPresentationStyle currentPresentationStyle;
@property (nonatomic) BOOL currentlyIsInitiallyInteractive;
@property (nonatomic) BOOL currentlyIsInteractive;
@property (nonatomic) BOOL currentlyIsCancelled;
@property (nonatomic) NSTimeInterval currentTransitionDuration;
@property (nonatomic) UIViewAnimationCurve currentCompletionCurve;
@property (weak, nonatomic) UIView *currentContainerView;

- (void)setToInitialCoordinatorContext;

- (void)animateZoomTransition;

@end

@implementation ETTransitionManager

- (id)init
{
  self = [super init];
  if (self) {
    [self setToInitialCoordinatorContext];
  }
  return self;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
  self.currentPresentedViewController = presented;
  self.currentPresentingViewController = presenting;
  self.currentSourceViewController = source;
  return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
  self.currentDismissedViewController = dismissed;
  return self;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
  if (self.currentlyIsInteractive) {
    return self;
  }
  return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
  if (self.currentlyIsInteractive) {
    return self;
  }
  return nil;
}

#pragma mark - UIViewControllerTransitionCoordinator

- (BOOL)animateAlongsideTransition:(void (^)(id<UIViewControllerTransitionCoordinatorContext>context))animation completion:(void (^)(id<UIViewControllerTransitionCoordinatorContext>context))completion
{
  return YES;
}

- (BOOL)animateAlongsideTransitionInView:(UIView *)view animation:(void (^)(id<UIViewControllerTransitionCoordinatorContext>context))animation completion:(void (^)(id<UIViewControllerTransitionCoordinatorContext>context))completion
{
  return YES;
}

- (void)notifyWhenInteractionEndsUsingBlock: (void (^)(id<UIViewControllerTransitionCoordinatorContext>context))handler
{
  // TODO: Implement.
}

#pragma mark - UIViewControllerTransitionCoordinatorContext

- (BOOL)isAnimated
{
  return YES;
}

- (UIModalPresentationStyle)presentationStyle
{
  return self.currentPresentationStyle;
}

- (BOOL)initiallyInteractive
{
  return self.currentlyIsInitiallyInteractive;
}

- (BOOL)isInteractive
{
  return self.currentlyIsInteractive;
}

- (BOOL)isCancelled
{
  return self.currentlyIsCancelled;
}

- (NSTimeInterval)transitionDuration
{
  return self.currentTransitionDuration;
}

- (CGFloat)percentComplete
{
  return 0.0f;
}

- (CGFloat)completionVelocity
{
  return 0.0f;
}

- (UIViewAnimationCurve)completionCurve
{
  return self.currentCompletionCurve;
}

- (UIViewController *)viewControllerForKey:(NSString *)key
{
  if (key == UITransitionContextFromViewControllerKey) {
    return self.currentSourceViewController;
  } else if (key == UITransitionContextToViewControllerKey) {
    return self.currentPresentedViewController;
  }
  return nil;
}

- (UIView *)containerView
{
  return self.currentContainerView;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
  return self.currentTransitionDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
  self.currentTransitionContext = transitionContext;
  if (self.currentAnimation == ETTransitionAnimationZoom) {
    [self animateZoomTransition];
  }
}

- (void)animationEnded:(BOOL)transitionCompleted
{
  // TODO: Implement.
}

#pragma mark - UIViewControllerInteractiveTransitioning (Supplementary)

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
  self.currentTransitionContext = transitionContext;
  // TODO: Implement.
}

- (CGFloat)completionSpeed
{
  return 0.0f;
}

#pragma mark - Private

- (void)setToInitialCoordinatorContext
{
  self.isLocked = NO;
  self.currentlyIsReversed = NO;
  self.currentAnimation = ETTransitionAnimationNone;
  self.currentZoomedOutView = nil;
  self.currentZoomedOutFrame = CGRectZero;
  
  self.currentPresentationStyle = UIModalPresentationCustom;
  self.currentlyIsInitiallyInteractive = NO;
  self.currentlyIsInteractive = NO;
  self.currentlyIsCancelled = NO;
  self.currentTransitionDuration = 0.3f;
  self.currentCompletionCurve = UIViewAnimationCurveEaseInOut;
  self.currentContainerView = ((UINavigationController *)((ETAppDelegate *)[UIApplication sharedApplication].delegate).navigationController).view;
}

- (void)animateZoomTransition
{
  UIView *containerView = [self.currentTransitionContext containerView];
  UIViewController *sourceViewController = [self.currentTransitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  UIViewController *presentedViewController = [self.currentTransitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  // Decide values.
  BOOL shouldZoomOut = self.currentlyIsReversed;
  CGRect inFrame = [self.currentTransitionContext finalFrameForViewController:
                    (shouldZoomOut ? presentedViewController : sourceViewController)];
  CGRect outFrame = self.currentZoomedOutFrame;
  CGRect finalFrame = shouldZoomOut ? outFrame : inFrame;
  CGRect initialFrame = shouldZoomOut ? inFrame : outFrame;
  CGFloat finalAlpha = shouldZoomOut ? 0.0f : 1.0f;
  CGFloat initialAlpha = shouldZoomOut ? 1.0f : 0.0f;
  // Setup views.
  UIView *presentedView = shouldZoomOut ? sourceViewController.view : presentedViewController.view;
  __block UIView *snapshotReferenceView;
  __block UIView *snapshotView;
  NSOperation *setupOperation = [NSBlockOperation blockOperationWithBlock:^{
    presentedView.frame = finalFrame;
    snapshotReferenceView = shouldZoomOut ? self.currentZoomedOutView : presentedView;
    if (!shouldZoomOut) {
      [containerView insertSubview:presentedView atIndex:0];
    }
    snapshotView = [snapshotReferenceView snapshotViewAfterScreenUpdates:YES];
    snapshotView.frame = CGRectMake(initialFrame.origin.x, initialFrame.origin.y, initialFrame.size.width,
                                    (initialFrame.size.width / finalFrame.size.height * finalFrame.size.height));
    snapshotView.alpha = initialAlpha;
    [containerView addSubview:snapshotView];
    if (shouldZoomOut) {
      [presentedView removeFromSuperview];
    }
  }];
  [[NSOperationQueue mainQueue] addOperation:setupOperation];
  // Animate views.
  NSOperation *animateOperation = [NSBlockOperation blockOperationWithBlock:^{
    void (^applyScalar)(CGFloat) = ^(CGFloat scalar) {
      snapshotView.layer.transform = CATransform3DMakeScale(1.0f, 1.0f, scalar);
      snapshotView.alpha = scalar;
    };
    [UIView animateKeyframesWithDuration:self.currentTransitionDuration delay:0.0f options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
      [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.2 animations:^{ applyScalar(shouldZoomOut ? 0.8f : 0.2f); }];
      [UIView addKeyframeWithRelativeStartTime:0.2 relativeDuration:0.6 animations:^{ applyScalar(shouldZoomOut ? 0.2f : 0.8f); }];
      [UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{ applyScalar(shouldZoomOut ? 0.0f : 1.0f); }];
      snapshotView.frame = finalFrame;
    } completion:^(BOOL finished) {
      // Finalize if possible.
      if (finished) {
        if (!shouldZoomOut) {
          [containerView bringSubviewToFront:presentedView];
          [snapshotView removeFromSuperview];
        }
        [self.currentTransitionContext completeTransition:YES];
      }
      // Teardown all.
      [self setToInitialCoordinatorContext];
    }];
  }];
  [animateOperation addDependency:setupOperation];
  [[NSOperationQueue mainQueue] addOperation:animateOperation];
}

@end
