//
//  ETEventViewCell.m
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/14/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETEventViewCell.h"

@interface ETEventViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *mainLabel;

@property (nonatomic, weak, getter = eventsLabelFormat) NSString *eventsLabelFormat;

@end

@implementation ETEventViewCell

+ (BOOL)requiresConstraintBasedLayout
{
  return YES;
}

#pragma mark - Public

- (void)setEventText:(NSString *)eventText
{
  if ([eventText isEqualToString:self.eventText]) return;
  _eventText = eventText;
  self.mainLabel.text = self.eventText;
}

#pragma mark - Private

@end
