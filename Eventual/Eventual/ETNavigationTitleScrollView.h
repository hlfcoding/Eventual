//
//  ETNavigationTitleScrollView.h
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/23/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ETNavigationItemType) {
  ETNavigationItemTypeLabel,
  ETNavigationItemTypeButton,
};

@interface ETNavigationTitleScrollView : UIScrollView

<ETNavigationCustomTitleView>

@property (nonatomic, strong, setter = setVisibleItem:) UIView *visibleItem;

- (UIView *)addItemOfType:(ETNavigationItemType)type withText:(NSString *)text;
- (void)processItems;

@end
