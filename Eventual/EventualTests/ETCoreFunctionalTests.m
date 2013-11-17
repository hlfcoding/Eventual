//
//  ETCoreFunctionalTests.m
//  Eventual
//
//  Created by Nest Master on 11/15/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETCoreFunctionalTests.h"

@interface ETCoreFunctionalTests ()

@property (strong, nonatomic) NSString *daysByMonthViewLabel;
@property (strong, nonatomic) NSString *eventsViewLabel;
@property (strong, nonatomic) NSString *firstDayViewLabel;
@property (strong, nonatomic) NSString *monthTitleViewLabel;

@end

@implementation ETCoreFunctionalTests

- (void)setUp
{
  self.daysByMonthViewLabel = NSLocalizedString(ETMonthDaysLabel, nil);
  self.eventsViewLabel = NSLocalizedString(ETDayEventsLabel, nil);
  self.firstDayViewLabel = [NSString stringWithFormat:NSLocalizedString(ETDayCellLabelFormat, nil), 0, 0];
  self.monthTitleViewLabel = NSLocalizedString(ETMonthScreenTitleLabel, nil);
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
  __block NSString *previousText = nil;
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
