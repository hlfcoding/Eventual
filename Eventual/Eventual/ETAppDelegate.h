//
//  ETAppDelegate.h
//  Eventual
//
//  Created by Peng Wang on 10/20/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETEventManager;
@class ETNavigationController;
@class ETTransitionManager;

@interface ETAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ETEventManager *eventManager;
@property (strong, nonatomic) ETNavigationController *navigationController;
@property (strong, nonatomic) ETTransitionManager *transitionManager;

@property (strong, nonatomic) UIColor *lightGrayColor;
@property (strong, nonatomic) UIColor *lightGrayIconColor;
@property (strong, nonatomic) UIColor *lightGrayTextColor;
@property (strong, nonatomic) UIColor *darkGrayTextColor;
@property (strong, nonatomic) UIColor *greenColor;

@property (nonatomic) CGFloat iconBarButtonItemFontSize;

@end
