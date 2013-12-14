//
//  ETDayViewCell.m
//  Eventual
//
//  Created by Nest Master on 11/5/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETDayViewCell.h"

@interface ETDayViewCell ()

@property (strong, nonatomic) IBOutlet UILabel *dayLabel;
@property (strong, nonatomic) IBOutlet UILabel *eventsLabel;

@property (weak, nonatomic, getter = eventsLabelFormat) NSString *eventsLabelFormat;

- (void)setUp;

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

- (void)tintColorDidChange
{
  self.eventsLabel.textColor = self.tintColor;
}

+ (BOOL)requiresConstraintBasedLayout
{
  return YES;
}

#pragma mark - Public

- (void)setDayText:(NSString *)dayText
{
  if ([dayText isEqualToString:self.dayText]) return;
  _dayText = dayText;
  self.dayLabel.text = [NSString stringWithFormat:@"%02d", self.dayText.integerValue];
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

- (NSString *)eventsLabelFormat
{
  static NSString *singularFormat;
  static NSString *pluralFormat;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    singularFormat = NSLocalizedString(@"%d event", nil).uppercaseString;
    pluralFormat = NSLocalizedString(@"%d events", nil).uppercaseString;
  });
  return (self.numberOfEvents > 1 ? pluralFormat : singularFormat);
}

@end
