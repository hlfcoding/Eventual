//
//  KIFUITestActor+ETAdditions.h
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/15/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

typedef void(^KIFETGetViewTextBlock)(NSString *text);
typedef NSString*(^KIFETCheckViewTextBlock)();

@interface KIFUITestActor (ETAdditions)

- (void)returnToPreviousScreen;

- (void)getTextForViewWithAccessibilityLabel:(NSString *)label
                            withGetTextBlock:(KIFETGetViewTextBlock)textBlock;

- (void)checkTextForViewWithAccessibilityLabel:(NSString *)label
                            withCheckTextBlock:(KIFETCheckViewTextBlock)textBlock
                           andExpectedEquality:(BOOL)expectedEquality;

- (UIView *)viewWithAccessibilityLabel:(NSString *)label;

@end
