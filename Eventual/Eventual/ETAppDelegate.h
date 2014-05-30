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

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) ETEventManager *eventManager;
@property (nonatomic, strong) ETNavigationController *navigationController;
@property (nonatomic, strong) ETTransitionManager *transitionManager;

@property (nonatomic, strong) UIColor *lightGrayColor;
@property (nonatomic, strong) UIColor *lightGrayIconColor;
@property (nonatomic, strong) UIColor *lightGrayTextColor;
@property (nonatomic, strong) UIColor *darkGrayTextColor;
@property (nonatomic, strong) UIColor *greenColor;

@property (nonatomic) CGFloat iconBarButtonItemFontSize;

@end
