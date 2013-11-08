//
//  ETNavigationController.m
//  Eventual
//
//  Created by Nest Master on 11/8/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETNavigationController.h"

#import "ETEventManager.h"

@interface ETNavigationController ()

- (void)setup;
- (void)setupViewController:(UIViewController *)viewController;

@end

@implementation ETNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) [self setup];
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) [self setup];
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view.
  [self setupViewController:self.visibleViewController];
  [self.eventManager completeSetup];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  UIViewController *viewController = segue.destinationViewController;
  [self setupViewController:viewController];
}

#pragma mark - Public

#pragma mark - Private

- (void)setup
{
  
}

- (void)setupViewController:(UIViewController *)viewController
{
  NSAssert(self.eventManager, @"Event manager should be set.");
  if ([viewController respondsToSelector:@selector(setEventManager:)]) {
    [viewController performSelector:@selector(setEventManager:) withObject:self.eventManager];
  }
}

@end
