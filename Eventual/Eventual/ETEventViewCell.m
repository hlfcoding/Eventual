//
//  ETEventViewCell.m
//  Eventual
//
//  Created by Nest Master on 11/14/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETEventViewCell.h"

@interface ETEventViewCell ()

@property (strong, nonatomic) IBOutlet UILabel *mainLabel;

@property (weak, nonatomic, getter = eventsLabelFormat) NSString *eventsLabelFormat;

@end

@implementation ETEventViewCell

#pragma mark - Public

- (void)setEventText:(NSString *)eventText
{
  if ([eventText isEqualToString:self.eventText]) return;
  _eventText = eventText;
  self.mainLabel.text = self.eventText;
}

#pragma mark - Private


@end
