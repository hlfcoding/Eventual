//
//  ETCoreFlowTests.m
//  Eventual
//
//  Created by Nest Master on 11/15/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETCoreFlowTests.h"

@implementation ETCoreFlowTests

- (void)beforeEach
{
  
}

- (void)afterEach
{
  
}

- (void)testSuccessfulNavigationToDay
{
  [tester waitForTappableViewWithAccessibilityLabel:@"Day-Cell-0-0"];
}

@end
