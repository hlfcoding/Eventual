//
//  ETNavigationController.m
//  Eventual
//
//  Created by Nest Master on 11/8/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETNavigationController.h"

#import "ETAppDelegate.h"
#import "ETEventManager.h"
#import "ETMonthsViewController.h"
#import "ETNavigationTitleView.h"

@interface ETNavigationController ()

@property (nonatomic) UIBarStyle defaultStyle;
@property (strong, nonatomic) UIColor *defaultTextColor;
@property (weak, nonatomic) ETAppDelegate *stylesheet;

- (void)setUp;
- (void)setUpViewController:(UIViewController *)viewController;
- (void)updateViewController:(UIViewController *)viewController;

@end

@implementation ETNavigationController

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
  self.defaultTextColor = self.stylesheet.darkGrayTextColor;
  [self setUpViewController:self.visibleViewController];
  [self updateViewController:self.visibleViewController];
  [self.eventManager completeSetup];
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

#pragma mark - Private

- (void)setUp
{
  self.delegate = self;
  self.stylesheet = [UIApplication sharedApplication].delegate;
  self.defaultStyle = UIBarStyleDefault;
}

- (void)setUpViewController:(UIViewController *)viewController
{
  NSAssert(self.eventManager, @"Event manager should be set.");
  if ([viewController respondsToSelector:@selector(setEventManager:)]) {
    [viewController performSelector:@selector(setEventManager:) withObject:self.eventManager];
  }
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
    UIView<ETNavigationCustomTitleView> *conformingTitleView = nil;
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
