//
//  ETNavigationController.m
//  Eventual
//
//  Created by Nest Master on 11/8/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETNavigationController.h"

#import "ETAppearanceManager.h"
#import "ETAppDelegate.h"
#import "ETEventManager.h"
#import "ETMonthsViewController.h"
#import "ETNavigationTitleView.h"

@interface ETNavigationController ()

@property (nonatomic) UIBarStyle defaultStyle;
@property (nonatomic, strong) UIColor *defaultTextColor;

- (void)setUp;
- (void)completeSetup;
- (void)setUpViewController:(UIViewController *)viewController;
- (void)updateViewController:(UIViewController *)viewController;

@end

@implementation ETNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
  self = [super initWithRootViewController:rootViewController];
  if (self) [self setUp];
  return self;
}

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
{
  self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
  if (self) [self setUp];
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) [self setUp];
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) [self setUp];
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view.
  [self completeSetup];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  [self setUpViewController:viewController];
  [super pushViewController:viewController animated:animated];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  [self updateViewController:viewController];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
  if ([self.transitioningDelegate conformsToProtocol:@protocol(UIViewControllerAnimatedTransitioning)]) {
    return (id<UIViewControllerAnimatedTransitioning>)self.transitioningDelegate;
  }
  return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
  if ([self.transitioningDelegate conformsToProtocol:@protocol(UIViewControllerInteractiveTransitioning)]) {
    return (id<UIViewControllerInteractiveTransitioning>)self.transitioningDelegate;
  }
  return nil;
}

#pragma mark - Private

- (void)setUp
{
  self.delegate = self;
  self.defaultStyle = UIBarStyleDefault;
  self.defaultTextColor = [ETAppearanceManager defaultManager].darkGrayTextColor;
}

- (void)completeSetup
{
  // Custom back button.
  UIViewController *rootViewController = self.viewControllers.firstObject;
  UINavigationItem *navigationItem = rootViewController.navigationItem;
  if ([navigationItem.leftBarButtonItem.title isEqualToString:ETLabelNavigationBack]) {
    [navigationItem setUpEventualLeftBarButtonItem];
  }
  // Initial view controllers.
  [[ETEventManager defaultManager] completeSetup];
  [self setUpViewController:self.visibleViewController];
  [self updateViewController:self.visibleViewController];
}

- (void)setUpViewController:(UIViewController *)viewController
{
}

- (void)updateViewController:(UIViewController *)viewController
{
  UIBarStyle style = self.defaultStyle;
  UIColor *textColor = self.defaultTextColor;
  if ([viewController conformsToProtocol:@protocol(ETNavigationAppearanceDelegate)]) {
    UIViewController<ETNavigationAppearanceDelegate> *conformingViewController = (UIViewController<ETNavigationAppearanceDelegate> *)viewController;
    if (conformingViewController.wantsAlternateNavigationBarAppearance) {
      style = UIBarStyleBlack;
      textColor = [UIColor whiteColor];
    }
  }
  //shouldCompensateForAppearanceUpdateDelay = YES;
  [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
    self.navigationBar.barStyle = style;
    if (style == UIBarStyleDefault) {
      self.navigationBar.barTintColor = [UIColor colorWithWhite:1.0f alpha:0.01f];
    }
    UIView<ETNavigationCustomTitleView> *conformingTitleView;
    if ([viewController.navigationItem.titleView conformsToProtocol:@protocol(ETNavigationCustomTitleView)]) {
      conformingTitleView = (UIView<ETNavigationCustomTitleView> *)viewController.navigationItem.titleView;
    }
    if (conformingTitleView) {
      conformingTitleView.textColor = textColor;
    } else {
      self.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName: textColor };
    }
  } completion:nil];
}

@end
