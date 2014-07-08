//
//  ETCoreFunctionalTests.m
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/15/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETCoreFunctionalTests.h"

@interface ETCoreFunctionalTests ()

@property (nonatomic, strong) NSString *daysByMonthViewLabel;
@property (nonatomic, strong) NSString *eventsViewLabel;
@property (nonatomic, strong) NSString *firstDayViewLabel;
@property (nonatomic, strong) NSString *monthTitleViewLabel;

@end

@implementation ETCoreFunctionalTests

- (void)setUp
{
  self.daysByMonthViewLabel = NSLocalizedString(ETLabelMonthDays, nil);
  self.eventsViewLabel = NSLocalizedString(ETLabelDayEvents, nil);
  self.firstDayViewLabel = [NSString stringWithFormat:NSLocalizedString(ETLabelFormatDayCell, nil), 0, 0];
  self.monthTitleViewLabel = NSLocalizedString(ETLabelMonthScreenTitle, nil);
}

- (void)beforeEach
{}

- (void)afterEach
{}

- (void)testSuccessfulNavigationToDay
{
  [tester waitForViewWithAccessibilityLabel:self.daysByMonthViewLabel];
  [tester waitForTappableViewWithAccessibilityLabel:self.firstDayViewLabel];
  [tester tapViewWithAccessibilityLabel:self.firstDayViewLabel];
  [tester waitForViewWithAccessibilityLabel:self.eventsViewLabel];
  [tester returnToPreviousScreen];
}

- (void)testSuccessfulMonthHeaderUpdate
{
  __block NSString *previousText;
  [tester waitForViewWithAccessibilityLabel:self.daysByMonthViewLabel];
  [tester waitForTappableViewWithAccessibilityLabel:self.firstDayViewLabel];
  [tester getTextForViewWithAccessibilityLabel:self.monthTitleViewLabel withGetTextBlock:^(NSString *text) {
    previousText = text;
  }];
  [tester scrollViewWithAccessibilityLabel:self.daysByMonthViewLabel byFractionOfSizeHorizontal:0.0f vertical:-0.5f];
  [tester checkTextForViewWithAccessibilityLabel:self.monthTitleViewLabel withCheckTextBlock:^NSString *{
    return previousText;
  } andExpectedEquality:NO];
}

@end
