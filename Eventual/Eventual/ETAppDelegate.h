//
//  ETAppDelegate.h
//  Eventual
//
//  Created by Peng Wang on 10/20/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETAppearanceManager;
@class ETEventManager;
@class ETNavigationController;

@interface ETAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) ETAppearanceManager *appearanceManager;
@property (nonatomic, strong) ETEventManager *eventManager;
@property (nonatomic, strong) ETNavigationController *navigationController;

@end
