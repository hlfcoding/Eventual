//
//  UINavigationItem+ETAdditions.m
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 1/30/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

#import "UINavigationItem+ETAdditions.h"

#import "ETAppearanceManager.h"

@implementation UINavigationItem (ETAdditions)

- (void)setUpEventualLeftBarButtonItem
{
  CGFloat iconFontSize = [ETAppearanceManager defaultManager].iconBarButtonItemFontSize;
  NSDictionary *attributes = @{ NSFontAttributeName:[UIFont fontWithName:@"eventual" size:iconFontSize]};
  [self.leftBarButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
  self.leftBarButtonItem.title = ETIconLeftArrow;
}

@end
