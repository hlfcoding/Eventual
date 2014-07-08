//
//  ETMonthHeaderView.m
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/6/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETMonthHeaderView.h"

@interface ETMonthHeaderView ()

@property (nonatomic, weak) IBOutlet UILabel *monthLabel;

@end

@implementation ETMonthHeaderView

+ (BOOL)requiresConstraintBasedLayout
{
  return YES;
}

#pragma mark - Public

- (void)setMonthName:(NSString *)monthName
{
  if ([monthName isEqualToString:self.monthName]) return;
  _monthName = monthName;
  self.monthLabel.text = monthName.uppercaseString;
}

@end
