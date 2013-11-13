//
//  ETNavigationTitleView.h
//  Eventual
//
//  Created by Nest Master on 11/12/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETNavigationTitleView : UIView

@property (strong, nonatomic, setter = setTextColor:) UIColor *textColor;

- (void)setText:(NSString *)text animated:(BOOL)animated;

@end
