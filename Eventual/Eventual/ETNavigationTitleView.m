//
//  ETNavigationTitleView.m
//  Eventual
//
//  Created by Nest Master on 11/12/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETNavigationTitleView.h"

@interface ETNavigationTitleView ()

@property (strong, nonatomic) IBOutlet UILabel *mainLabel;
@property (strong, nonatomic) IBOutlet UILabel *interstitialLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *mainConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *interstitialConstraint;

- (void)setUp;

@end

@implementation ETNavigationTitleView

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

+ (BOOL)requiresConstraintBasedLayout
{
  return YES;
}

#pragma mark - ETNavigationCustomTitleView

- (void)setTextColor:(UIColor *)textColor
{
  if ([textColor isEqual:self.textColor]) return;
  _textColor = textColor;
  self.mainLabel.textColor = self.interstitialLabel.textColor = self.textColor;
}

#pragma mark - Public

- (NSString *)text
{
  return self.mainLabel.text;
}

- (void)setText:(NSString *)text animated:(BOOL)animated
{
  if ([text isEqualToString:self.mainLabel.text]) return;
  if (!animated) {
    self.mainLabel.text = text;
    return;
  }
  self.interstitialLabel.text = text;
  CGFloat savedMainConstant = self.mainConstraint.constant;
  CGFloat savedInterstitialConstant = self.interstitialConstraint.constant;
  self.mainConstraint.constant = -self.mainLabel.frame.size.height;
  self.interstitialConstraint.constant = 0.0f;
  [self setNeedsUpdateConstraints];
  [UIView animateWithDuration:0.3f animations:^{
    [self layoutIfNeeded];
  } completion:^(BOOL finished) {
    self.mainLabel.text = self.interstitialLabel.text;
    self.mainConstraint.constant = savedMainConstant;
    self.interstitialConstraint.constant = savedInterstitialConstant;
  }];
}

#pragma mark - Private

- (void)setUp
{
  self.clipsToBounds = YES;
  self.isAccessibilityElement = YES;
  self.accessibilityLabel = NSLocalizedString(ETMonthScreenTitleLabel, nil);
}

@end
