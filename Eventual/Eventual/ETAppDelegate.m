//
//  ETAppDelegate.m
//  Eventual
//
//  Created by Peng Wang on 10/20/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETAppDelegate.h"

#import "ETMonthHeaderView.h"

@interface ETAppDelegate ()

- (void)applyMainStyle;

@end

@implementation ETAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifndef DEBUG
  [TestFlight takeOff:@"8d80497e-527a-4ce3-870e-e130b0f48c33"];
#endif
  [self applyMainStyle];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

#pragma mark - Private

- (void)applyMainStyle
{
  self.lightGrayColor = [UIColor colorWithWhite:0.89f alpha:1.0f];
  self.lightGrayTextColor = [UIColor colorWithWhite:0.77f alpha:1.0f];
  
  [[UILabel appearance]
   setBackgroundColor:[UIColor clearColor]];

  [[UICollectionView appearance]
   setBackgroundColor:self.lightGrayColor];
  [[UICollectionViewCell appearance]
   setBackgroundColor:[UIColor whiteColor]];
  [[UICollectionReusableView appearance]
   setBackgroundColor:[UIColor clearColor]];
  [[UILabel appearanceWhenContainedIn:[ETMonthHeaderView class], nil]
   setTextColor:self.lightGrayTextColor];
}

@end