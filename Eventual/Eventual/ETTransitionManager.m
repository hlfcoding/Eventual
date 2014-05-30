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

@property (nonatomic, weak) UIViewController *dismissedViewController;
@property (nonatomic, weak) UIViewController *presentedViewController;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, weak) UIViewController *sourceViewController;
@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;

@property (nonatomic, getter = isZoomCancelled) BOOL zoomCancelled;

- (void)setToInitialContext;
- (void)animate;

@end

@implementation ETTransitionManager

- (id)init
{
  self = [super init];
  if (self) {
    [self setToInitialContext];
  }
  return self;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
  self.presentedViewController = presented;
  self.presentingViewController = presenting;
  self.sourceViewController = source;
  return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
  self.dismissedViewController = dismissed;
  return self;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
  if (self.isZoomInteractive) {
    return self;
  }
  return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
  if (self.isZoomInteractive) {
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

- (void)notifyWhenInteractionEndsUsingBlock:(void (^)(id<UIViewControllerTransitionCoordinatorContext>context))handler
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
  return UIModalPresentationCustom;
}

- (BOOL)initiallyInteractive
{
  return self.isZoomInteractive;
}

- (BOOL)isInteractive
{
  return self.isZoomInteractive;
}

- (BOOL)isCancelled
{
  return self.isZoomCancelled;
}

- (NSTimeInterval)transitionDuration
{
  return 0.3f;
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
  return self.zoomCompletionCurve;
}

- (UIViewController *)viewControllerForKey:(NSString *)key
{
  if (key == UITransitionContextFromViewControllerKey) {
    return self.sourceViewController;
  } else if (key == UITransitionContextToViewControllerKey) {
    return self.presentedViewController;
  }
  return nil;
}

- (UIView *)containerView
{
  return self.containerView;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
  return self.zoomDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
  self.transitionContext = transitionContext;
  [self animate];
}

- (void)animationEnded:(BOOL)transitionCompleted
{
  [self setToInitialContext];
}

#pragma mark - UIViewControllerInteractiveTransitioning (Supplementary)

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
  self.transitionContext = transitionContext;
  // TODO: Implement.
}

- (CGFloat)completionSpeed
{
  return 0.0f;
}

#pragma mark - Private

- (void)setToInitialContext
{
  self.zoomContainerView = nil;
  self.zoomedOutView = nil;
  self.zoomedOutFrame = CGRectZero;

  self.zoomDuration = 0.3f;
  self.zoomCompletionCurve = UIViewAnimationCurveEaseInOut;
  self.zoomReversed = NO;
  self.zoomInteractive = NO;
}

- (void)animate
{
  UIView *containerView = [self.transitionContext containerView];
  UIViewController *sourceViewController = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  UIViewController *presentedViewController = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  // Decide values.
  BOOL shouldZoomOut = self.isZoomReversed;
  CGRect inFrame = [self.transitionContext finalFrameForViewController:
                    (shouldZoomOut ? presentedViewController : sourceViewController)];
  CGRect outFrame = self.zoomedOutFrame;
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
    snapshotReferenceView = shouldZoomOut ? self.zoomedOutView : presentedView;
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
    [UIView animateKeyframesWithDuration:self.zoomDuration delay:0.0f options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
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
        [self.transitionContext completeTransition:YES];
      }
    }];
  }];
  [animateOperation addDependency:setupOperation];
  [[NSOperationQueue mainQueue] addOperation:animateOperation];
}

@end
