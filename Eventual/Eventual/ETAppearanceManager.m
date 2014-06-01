//
//  ETAppearanceManager.m
//  Eventual
//
//  Created by Peng Wang on 5/30/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

#import "ETAppearanceManager.h"

#import "ETAppDelegate.h"
#import "ETMonthHeaderView.h"
#import "ETMonthsViewController.h"

@interface ETAppearanceManager ()
@end

@implementation ETAppearanceManager

- (id)init
{
  self = [super init];
  if (self) {
    self.lightGrayColor = [UIColor colorWithRed:0.89f green:0.89f blue:0.89f alpha:1.0f];
    self.lightGrayIconColor = [UIColor colorWithRed:0.85f green:0.85f blue:0.85f alpha:1.0f];
    self.lightGrayTextColor = [UIColor colorWithRed:0.77f green:0.77f blue:0.77f alpha:1.0f];
    self.darkGrayTextColor = [UIColor colorWithRed:0.39 green:0.39 blue:0.39 alpha:1.0f];
    self.blueColor = [UIColor colorWithRed:0.0f green:0.48f blue:1.0f alpha:1.0f];
    self.greenColor = [UIColor colorWithRed:0.14f green:0.74f blue:0.34f alpha:1.0f];
    self.iconBarButtonItemFontSize = 36.0f;
    [self applyMainStyle];
  }
  return self;
}

#pragma mark - Public

- (void)applyMainStyle
{
  [UIView appearance].tintColor = self.blueColor;
  [UILabel appearance].backgroundColor = [UIColor clearColor];

  [UIView appearanceWhenContainedIn:[UINavigationBar class], nil].backgroundColor = [UIColor clearColor];

  [UICollectionView appearance].backgroundColor = [UIColor whiteColor];
  [UICollectionView appearanceWhenContainedIn:[ETMonthsViewController class], nil].backgroundColor = self.lightGrayColor;
  [UICollectionViewCell appearance].backgroundColor = [UIColor whiteColor];
  [UICollectionViewCell appearanceWhenContainedIn:[ETMonthsViewController class], nil].backgroundColor = self.blueColor;
  [UICollectionReusableView appearance].backgroundColor = [UIColor clearColor];
  [UILabel appearanceWhenContainedIn:[ETMonthHeaderView class], nil].textColor = self.lightGrayTextColor;

  // TODO: Navigation title font appearance.
}

+ (ETAppearanceManager *)defaultManager
{
  return ((ETAppDelegate *)[UIApplication sharedApplication].delegate).appearanceManager;
}

#pragma mark - Private

@end
