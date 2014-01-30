//
//  ETNavigationTitleScrollView.m
//  Eventual
//
//  Created by Nest Master on 11/23/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETNavigationTitleScrollView.h"

@interface ETNavigationTitleScrollView ()

<UIScrollViewDelegate>

- (void)setUp;
- (void)setUpLayoutForSubview:(UIView *)subview;
- (void)updateContentSizeForSubview:(UIView *)subview;
- (void)updateTextColors;
- (void)updateVisibleItem;

- (UIButton *)newButton;
- (UILabel *)newLabel;

@end

@implementation ETNavigationTitleScrollView

@synthesize textColor = _textColor;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) [self setUp];
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) [self setUp];
  return self;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  static CGFloat previousOffset = -1.0f;
  static const CGFloat throttleThresholdOffset = 2.0f;
  CGFloat offset = self.contentOffset.x;
  if (previousOffset == -1.0f) previousOffset = offset;
  else if (fabsf(offset - previousOffset) < throttleThresholdOffset) return;
  else {
    previousOffset = offset;
    [self updateTextColors];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  [self updateVisibleItem];
}

#pragma mark - ETNavigationCustomTitleView

- (void)setTextColor:(UIColor *)textColor
{
  _textColor = textColor;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self updateTextColors];
  });
}

#pragma mark - Public

- (void)setVisibleItem:(UIView *)visibleItem
{
  if (visibleItem == _visibleItem) return;
  _visibleItem = visibleItem;
  if (self.visibleItem) {
    [self setContentOffset:CGPointMake(self.visibleItem.frame.origin.x, self.contentOffset.y) animated:YES];
  }
}

- (UIView *)addItemOfType:(ETNavigationItemType)type withText:(NSString *)text
{
  UIView *subview;
  if (type == ETNavigationItemTypeButton) {
    UIButton *button = [self newButton];
    [button setTitle:text forState:UIControlStateNormal];
    subview = button;
  } else {
    UILabel *label = [self newLabel];
    label.text = text;
    subview = label;
  }
  subview.isAccessibilityElement = YES;
  [subview sizeToFit];
  [self updateContentSizeForSubview:subview];
  return subview;
}

- (void)processItems
{
  [self updateVisibleItem];
}

- (BOOL)requestUpdateTextColors
{
  [self updateTextColors];
  return YES;
}

#pragma mark - Private

- (void)setUp
{
  self.delegate = self;
  self.clipsToBounds = NO;
  self.scrollEnabled = YES;
  self.pagingEnabled = YES;
  self.showsHorizontalScrollIndicator = self.showsVerticalScrollIndicator = NO;
}

- (void)setUpLayoutForSubview:(UIView *)subview
{
  subview.translatesAutoresizingMaskIntoConstraints = NO;
  if ([self.subviews indexOfObject:subview] == NSNotFound) {
    [self addSubview:subview];
  }
  [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterY
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self attribute:NSLayoutAttributeCenterY
                                                  multiplier:1.0f constant:0.0f]];
  [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeWidth
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self attribute:NSLayoutAttributeWidth
                                                  multiplier:1.0f constant:0.0f]];
  if (self.subviews.count > 1) {
    UIView *previousSibling = self.subviews[[self.subviews indexOfObject:subview] - 1];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:previousSibling attribute:NSLayoutAttributeTrailing
                                                    multiplier:1.0f constant:0.0f]];
  } else {
    [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0f constant:0.0f]];
  }
}

- (void)updateContentSizeForSubview:(UIView *)subview
{
  self.contentSize = CGSizeMake(self.contentSize.width + self.frame.size.width, self.contentSize.height);
}

- (void)updateTextColors
{
  static const CGFloat dynamicRange = 0.8f;
  CGFloat offset = self.contentOffset.x;
  const CGFloat *rgb = CGColorGetComponents(self.textColor.CGColor);
  for (UIView *subview in self.subviews) {
    CGFloat ratio = 1.0f - dynamicRange * MIN(fabsf(subview.frame.origin.x - offset) / subview.frame.size.width, 1.0f);
    UIColor *color = [UIColor colorWithRed:rgb[0] green:rgb[1] blue:rgb[2] alpha:1.0f * ratio];
    if ([subview isKindOfClass:[UIButton class]]) {
      [(UIButton *)subview setTitleColor:color forState:UIControlStateNormal];
    } else {
      [(UILabel *)subview setTextColor:color];
    }
  }
}

- (void)updateVisibleItem
{
  if (!self.visibleItem) {
    self.visibleItem = self.subviews.firstObject;
  } else {
    for (UIView *subview in self.subviews) {
      if (subview.frame.origin.x == self.contentOffset.x) {
        self.visibleItem = subview;
      }
    }
  }
}

- (UIButton *)newButton
{
  UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
  button.isAccessibilityElement = YES;
  button.titleLabel.font = [UIFont boldSystemFontOfSize:button.titleLabel.font.pointSize];
  button.titleLabel.textAlignment = NSTextAlignmentCenter;
  [self setUpLayoutForSubview:button];
  return button;
}

- (UILabel *)newLabel
{
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
  label.isAccessibilityElement = YES;
  label.font = [UIFont boldSystemFontOfSize:label.font.pointSize];
  label.textAlignment = NSTextAlignmentCenter;
  [self setUpLayoutForSubview:label];
  return label;
}

@end
