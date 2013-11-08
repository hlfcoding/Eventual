//
//  ETEventManager.m
//  Eventual
//
//  Created by Nest Master on 11/7/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETEventManager.h"

#import <EventKit/EventKit.h>

NSString *const ETEntityAccessRequestNotification = @"ETEntityAccess";

NSString *const ETEntityAccessRequestNotificationDenied = @"ETEntityAccessDenied";
NSString *const ETEntityAccessRequestNotificationError = @"ETEntityAccessError";
NSString *const ETEntityAccessRequestNotificationGranted = @"ETEntityAccessGranted";

NSString *const ETEntityAccessRequestNotificationErrorKey = @"ETEntityAccessErrorKey";
NSString *const ETEntityAccessRequestNotificationResultKey = @"ETEntityAccessResultKey";
NSString *const ETEntityAccessRequestNotificationTypeKey = @"ETEntityAccessTypeKey";

@interface ETEventManager ()

@property (strong, nonatomic, readwrite, setter = setEvents:) NSArray *events;
@property (strong, nonatomic) EKEventStore *store;

@property (strong, nonatomic) NSArray *calendars;
@property (strong, nonatomic) EKCalendar *calendar;

@property (strong, nonatomic) NSOperationQueue *operationQueue;

- (void)setup;

@end

@implementation ETEventManager

- (id)init
{
  self = [super init];
  if (self) [self setup];
  return self;
}

#pragma mark - Public

- (void)setEvents:(NSArray *)events
{
  if (events && events == self.events) return;
  _events = events ? events : @[];
}

- (void)completeSetup
{
  [self.store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *accessError) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[ETEntityAccessRequestNotificationTypeKey] = @( EKEntityTypeEvent );
    if (granted) {
      userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationGranted;
      self.calendars = [self.store calendarsForEntityType:EKEntityTypeEvent];
      self.calendar = self.store.defaultCalendarForNewEvents;
    } else if (!granted) {
      userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationDenied;
    } else if (accessError) {
      userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationError;
      userInfo[ETEntityAccessRequestNotificationErrorKey] = accessError;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ETEntityAccessRequestNotification object:self
                                                      userInfo:userInfo];
  }];
}

- (NSOperation *)fetchEventsFromDate:(NSDate *)startDate untilDate:(NSDate *)endDate completion:(ETFetchEventsCompletionHandler)completion
{
  if (!startDate) {
    startDate = [NSDate date];
  }
  NSAssert(endDate, @"`endDate` is required.");
  NSAssert(completion, @"`completion` is required.");
  NSPredicate *predicate = [self.store predicateForEventsWithStartDate:startDate endDate:endDate calendars:self.calendars];
  NSOperation *fetchOperation = [NSBlockOperation blockOperationWithBlock:^{
    NSArray *events = [self.store eventsMatchingPredicate:predicate];
    self.events = events;
  }];
  [fetchOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
  NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:completion];
  [completionOperation addDependency:fetchOperation];
  [self.operationQueue addOperation:fetchOperation];
  [[NSOperationQueue mainQueue] addOperation:completionOperation];
  return fetchOperation;
}

#pragma mark - Private

- (void)setup
{
  self.store = [[EKEventStore alloc] init];
  self.operationQueue = [[NSOperationQueue alloc] init];
}

@end
