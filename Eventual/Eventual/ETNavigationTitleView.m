//
//  ETNavigationTitleView.m
//  Eventual
//
//  Created by Nest Master on 11/12/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETNavigationTitleView.h"

@interface ETNavigationTitleView ()

@property (nonatomic, weak) IBOutlet UILabel *mainLabel;
@property (nonatomic, weak) IBOutlet UILabel *interstitialLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mainConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *interstitialConstraint;

@property (nonatomic, getter = isAnimatingText) BOOL animatingText;

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
  const NSTimeInterval duration = 0.3f;
  if (!animated) {
    if ([text isEqualToString:self.mainLabel.text]) return;
    self.mainLabel.text = text;
    return;
  }
  if ([text isEqualToString:self.interstitialLabel.text]) return;
  // TODO: Make this animation interruptible with new API in iOS8.
  if (self.isAnimatingText) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self setText:text animated:YES];
    });
    return;
  }
  self.animatingText = YES;
  self.interstitialLabel.text = text;
  CGFloat savedMainConstant = self.mainConstraint.constant;
  CGFloat savedInterstitialConstant = self.interstitialConstraint.constant;
  self.mainConstraint.constant = -self.mainLabel.frame.size.height;
  self.interstitialConstraint.constant = 0.0f;
  [self setNeedsUpdateConstraints];
  [UIView
   animateWithDuration:duration delay:0.0f
   options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
   animations:^{
     [self layoutIfNeeded];
   }
   completion:^(BOOL finished) {
     self.animatingText = NO;
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
  self.accessibilityLabel = NSLocalizedString(ETLabelMonthScreenTitle, nil);
}

@end
