//
//  ETNavigationTitleScrollView.m
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/23/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETNavigationTitleScrollView.h"

@interface ETNavigationTitleScrollView ()

<UIScrollViewDelegate>

@property (nonatomic) BOOL shouldLayoutMasks;

- (void)setUp;
- (void)setUpSubview:(UIView *)subview;
- (void)updateContentSizeForSubview:(UIView *)subview;
- (void)updateTextAppearance;
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

- (void)layoutSubviews
{
  [super layoutSubviews];
  if (self.shouldLayoutMasks) {
    for (UIView *subview in self.subviews) {
      CAGradientLayer *maskLayer = (CAGradientLayer *)subview.layer.mask;
      if (CGSizeEqualToSize(maskLayer.frame.size, subview.bounds.size)) {
        self.shouldLayoutMasks = NO;
        break;
      }
      maskLayer.frame = subview.bounds;
    }
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  static const CGFloat throttleThresholdOffset = 1.0f;
  static CGFloat previousOffset = -1.0f;
  CGFloat offset = self.contentOffset.x;
  if (previousOffset == -1.0f) previousOffset = offset;
  else if (fabsf(offset - previousOffset) < throttleThresholdOffset) return;
  else {
    previousOffset = offset;
    [self updateTextAppearance];
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
    [self updateTextAppearance];
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
  self.shouldLayoutMasks = YES;
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

#pragma mark - Private

- (void)setUp
{
  self.delegate = self;
  self.clipsToBounds = NO;
  self.scrollEnabled = YES;
  self.pagingEnabled = YES;
  self.showsHorizontalScrollIndicator = self.showsVerticalScrollIndicator = NO;
}

- (void)setUpSubview:(UIView *)subview
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
  CAGradientLayer *maskLayer = [CAGradientLayer layer];
  maskLayer.startPoint = CGPointMake(0.0f, 0.5f);
  maskLayer.endPoint = CGPointMake(1.0f, 0.5f);
  maskLayer.masksToBounds = YES;
  maskLayer.colors = @[ (id)[UIColor whiteColor].CGColor, (id)[UIColor whiteColor].CGColor ];
  maskLayer.locations = @[ @(0.0f), @(1.0f)];
  subview.layer.mask = maskLayer;
}

- (void)updateContentSizeForSubview:(UIView *)subview
{
  self.contentSize = CGSizeMake(self.contentSize.width + self.frame.size.width, self.contentSize.height);
}

- (void)updateTextAppearance
{
  static const CGFloat colorScalar = 0.5f;
  static const CGFloat maskScalar = 2.5f;
  static const CGFloat offsetThreshold = 95.0f;
  static const CGFloat siblingThreshold = offsetThreshold / 2.0f;
  static NSArray *priorMaskColors;
  static NSArray *subsequentMaskColors;
  static NSArray *currentMaskColorsAndLocations;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    priorMaskColors = @[ (id)[UIColor clearColor].CGColor, (id)[UIColor whiteColor].CGColor ];
    subsequentMaskColors = @[ (id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor ];
    currentMaskColorsAndLocations = @[ @[ (id)[UIColor whiteColor].CGColor, (id)[UIColor whiteColor].CGColor ],
                                       @[ @(0.0f), @(1.0f) ] ];
  });
  const CGFloat *rgb = CGColorGetComponents(self.textColor.CGColor);
  CGFloat contentOffset = self.contentOffset.x;
  for (UIView *subview in self.subviews) {
    CGFloat offset = subview.frame.origin.x - contentOffset;
    BOOL isPriorSibling = offset < -siblingThreshold;
    BOOL isSubsequentSibling = offset > siblingThreshold;
    CGFloat colorRatio = colorScalar * MIN(fabsf(offset) / subview.frame.size.width, 1.0f);
    // Update color.
    UIColor *color = [UIColor colorWithRed:rgb[0] green:rgb[1] blue:rgb[2] alpha:(1.0f - colorRatio)];
    if ([subview isKindOfClass:[UIButton class]]) {
      [(UIButton *)subview setTitleColor:color forState:UIControlStateNormal];
    } else {
      [(UILabel *)subview setTextColor:color];
    }
    // Update mask.
    CAGradientLayer *maskLayer = (CAGradientLayer *)subview.layer.mask;
    CGFloat maskRatio = maskScalar * MIN((fabsf(offset) - offsetThreshold) / subview.frame.size.width, 1.0f);
    if (isPriorSibling) {
      maskLayer.colors = priorMaskColors;
      maskLayer.locations = @[ @( maskRatio ), @1.0f ];
    } else if (isSubsequentSibling) {
      maskLayer.colors = subsequentMaskColors;
      maskLayer.locations = @[ @0.0f, @( 1.0f - maskRatio ) ];
    } else {
      maskLayer.colors = currentMaskColorsAndLocations.firstObject;
      maskLayer.locations = currentMaskColorsAndLocations.lastObject;
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
  [self setUpSubview:button];
  return button;
}

- (UILabel *)newLabel
{
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
  label.isAccessibilityElement = YES;
  label.font = [UIFont boldSystemFontOfSize:label.font.pointSize];
  label.textAlignment = NSTextAlignmentCenter;
  [self setUpSubview:label];
  return label;
}

@end
