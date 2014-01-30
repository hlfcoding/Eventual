//
//  UINavigationItem+ETAdditions.m
//  Eventual
//
//  Created by Nest Master on 1/30/14.
//  Copyright (c) 2014 Hashtag Studio. All rights reserved.
//

#import "UINavigationItem+ETAdditions.h"

#import "ETAppDelegate.h"

@implementation UINavigationItem (ETAdditions)

- (void)setUpEventualLeftBarButtonItem
{
  ETAppDelegate *stylesheet = (ETAppDelegate *)[UIApplication sharedApplication].delegate;
  NSDictionary *attributes = @{ NSFontAttributeName: [UIFont fontWithName:@"eventual" size:stylesheet.iconBarButtonItemFontSize] };
  [self.leftBarButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
  self.leftBarButtonItem.title = ETIconLeftArrow;
}

@end
