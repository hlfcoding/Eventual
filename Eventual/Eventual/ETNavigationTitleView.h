//
//  ETNavigationTitleView.h
//  Eventual
//
//  Created by Nest Master on 11/12/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETNavigationTitleView : UIView

<ETNavigationCustomTitleView>

@property (weak, nonatomic, readonly, getter = text) NSString *text;

- (void)setText:(NSString *)text animated:(BOOL)animated;

@end
