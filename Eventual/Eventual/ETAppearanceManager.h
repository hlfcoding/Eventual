//
//  ETAppearanceManager.h
//  Eventual
//
//  Created by Peng Wang on 5/30/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETAppearanceManager : NSObject

@property (nonatomic, strong) UIColor *lightGrayColor;
@property (nonatomic, strong) UIColor *lightGrayIconColor;
@property (nonatomic, strong) UIColor *lightGrayTextColor;
@property (nonatomic, strong) UIColor *darkGrayTextColor;
@property (nonatomic, strong) UIColor *blueColor;
@property (nonatomic, strong) UIColor *greenColor;

@property (nonatomic) CGFloat iconBarButtonItemFontSize;

- (void)applyMainStyle;

+ (ETAppearanceManager *)defaultManager;

@end
