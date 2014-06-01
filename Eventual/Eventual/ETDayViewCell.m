//
//  ETDayViewCell.m
//  Eventual
//
//  Created by Nest Master on 11/5/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETDayViewCell.h"

@interface ETDayViewCell ()

@property (nonatomic, strong) NSString *defaultBorderInsetsString;

@property (nonatomic, strong) IBOutlet UILabel *dayLabel;
@property (nonatomic, strong) IBOutlet UILabel *eventsLabel;
@property (nonatomic, strong) IBOutlet UIView *labelSeparator;
@property (nonatomic, strong) IBOutlet UIView *todayIndicator;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *borderTopConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *borderLeftConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *borderBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *borderRightConstraint;

@property (nonatomic, weak, getter = eventsLabelFormat) NSString *eventsLabelFormat;

- (void)setUp;
- (void)completeSetup;

@end

@implementation ETDayViewCell

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

- (void)awakeFromNib
{
  [super awakeFromNib];
  [self completeSetup];
}

- (void)tintColorDidChange
{
  self.dayLabel.textColor = self.tintColor;
  self.labelSeparator.backgroundColor = self.tintColor;
  self.todayIndicator.backgroundColor = self.tintColor;
}

+ (BOOL)requiresConstraintBasedLayout
{
  return YES;
}

#pragma mark - Public

- (UIEdgeInsets)defaultBorderInsets
{
  return UIEdgeInsetsFromString(self.defaultBorderInsetsString);
}

- (void)setBorderInsets:(UIEdgeInsets)borderInsets
{
  if (UIEdgeInsetsEqualToEdgeInsets(borderInsets, _borderInsets)) return;
  _borderInsets = borderInsets;
  self.borderTopConstraint.constant = borderInsets.top;
  self.borderLeftConstraint.constant = borderInsets.left;
  self.borderBottomConstraint.constant = borderInsets.bottom;
  self.borderRightConstraint.constant = borderInsets.right;
}

- (void)setDayText:(NSString *)dayText
{
  if ([dayText isEqualToString:self.dayText]) return;
  _dayText = dayText;
  self.dayLabel.text = [NSString stringWithFormat:@"%02ld", (long)self.dayText.integerValue];
}

- (void)setIsToday:(BOOL)isToday
{
  _isToday = isToday;
  self.todayIndicator.hidden = !self.isToday;
}

- (void)setNumberOfEvents:(NSUInteger)numberOfEvents
{
  if (numberOfEvents == self.numberOfEvents) return;
  _numberOfEvents = numberOfEvents;
  self.eventsLabel.text = [NSString stringWithFormat:self.eventsLabelFormat, self.numberOfEvents];
}

- (void)setAccessibilityLabelsWithIndexPath:(NSIndexPath *)indexPath
{
  self.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(ETLabelFormatDayCell, nil),
                             indexPath.section, indexPath.item];
}

#pragma mark - Private

- (void)setUp
{
  self.isAccessibilityElement = YES;
}

- (void)completeSetup
{
  self.borderInsets = UIEdgeInsetsMake(self.borderTopConstraint.constant, self.borderLeftConstraint.constant,
                                       self.borderBottomConstraint.constant, self.borderRightConstraint.constant);
  self.defaultBorderInsetsString = NSStringFromUIEdgeInsets(self.borderInsets);
}

- (NSString *)eventsLabelFormat
{
  static NSString *singularFormat;
  static NSString *pluralFormat;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    singularFormat = NSLocalizedString(@"%d event", nil);
    pluralFormat = NSLocalizedString(@"%d events", nil);
  });
  return (self.numberOfEvents > 1 ? pluralFormat : singularFormat);
}

@end
