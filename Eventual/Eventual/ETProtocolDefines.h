//
//  ETProtocolDefines.h
//  Eventual
//
//  Created by Nest Master on 11/13/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ETNavigationAppearanceDelegate <NSObject>

- (BOOL)wantsAlternateNavigationBarAppearance;

@end

@protocol ETNavigationCustomTitleView <NSObject>

@property (nonatomic, strong, setter = setTextColor:) UIColor *textColor;

@end