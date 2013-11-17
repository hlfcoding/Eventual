//
//  KIFUITestActor+ETAdditions.m
//  Eventual
//
//  Created by Nest Master on 11/15/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "KIFUITestActor+ETAdditions.h"
#import <KIF/UIAccessibilityElement-KIFAdditions.h>
#import <KIF/UIApplication-KIFAdditions.h>

@implementation KIFUITestActor (ETAdditions)

- (void)returnToPreviousScreen
{
  [self tapViewWithAccessibilityLabel:NSLocalizedString(@"Back", nil)];
}

- (void)getTextForViewWithAccessibilityLabel:(NSString *)label withGetTextBlock:(KIFETGetViewTextBlock)textBlock
{
  [self runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
    UIView *view = [self viewWithAccessibilityLabel:label];
    SEL textSelector = @selector(text);
    if (!view || ![view respondsToSelector:textSelector]) {
      KIFTestCondition(NO, error, @"Accessibility element with label \"%@\" is invalid", label);
      return KIFTestStepResultFailure;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *text = (NSString *)[view performSelector:textSelector];
#pragma clang diagnostic pop
    textBlock(text);
    return KIFTestStepResultSuccess;
  }];
}

- (void)checkTextForViewWithAccessibilityLabel:(NSString *)label withCheckTextBlock:(KIFETCheckViewTextBlock)textBlock andExpectedEquality:(BOOL)expectedEquality
{
  [self runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
    UIView *view = [self viewWithAccessibilityLabel:label];
    SEL textSelector = @selector(text);
    if (!view || ![view respondsToSelector:textSelector]) {
      KIFTestCondition(NO, error, @"Accessibility element with label \"%@\" is invalid", label);
      return KIFTestStepResultFailure;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *text = (NSString *)[view performSelector:textSelector];
#pragma clang diagnostic pop
    NSString *reference = textBlock();
    BOOL equality = [text isEqualToString:reference];
    //NSLog(@"%@, %@", text, reference);
    KIFTestCondition(equality == expectedEquality, error, @"Accessibility element with label \"%@\" has unexpected text \"%@\"", label, text);
    return KIFTestStepResultSuccess;
  }];
}

#pragma mark - Helpers

- (UIView *)viewWithAccessibilityLabel:(NSString *)label
{
  UIAccessibilityElement *element = [[UIApplication sharedApplication] accessibilityElementWithLabel:label
                                                                                  accessibilityValue:nil traits:UIAccessibilityTraitNone];
  if (!element) return nil;
  UIView *view = [UIAccessibilityElement viewContainingAccessibilityElement:element];
  return view;
}

@end
