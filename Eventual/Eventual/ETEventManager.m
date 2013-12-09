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
@property (strong, nonatomic, readwrite) NSDictionary *eventsByMonthsAndDays;

@property (strong, nonatomic, readwrite) EKEventStore *store;

@property (strong, nonatomic) NSArray *calendars;
@property (strong, nonatomic) EKCalendar *calendar;

@property (strong, nonatomic) NSOperationQueue *operationQueue;

- (void)setUp;

@end

@implementation ETEventManager

- (id)init
{
  self = [super init];
  if (self) [self setUp];
  return self;
}

#pragma mark - Public

- (void)setEvents:(NSArray *)events
{
  if (events && events == self.events) return;
  _events = events ? events : @[];
  self.eventsByMonthsAndDays = nil;
}

- (NSDictionary *)eventsByMonthsAndDays
{
  if (!self.events) {
    NSLog(@"WARNING: Trying to access events before fetching.");
    return nil;
  }
  if (!_eventsByMonthsAndDays) {
    NSMutableDictionary *events = [NSMutableDictionary dictionary];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    for (EKEvent *event in self.events) {
      NSDateComponents *monthComponents = [calendar components:NSMonthCalendarUnit|NSYearCalendarUnit fromDate:event.startDate];
      NSDateComponents *dayComponents = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:event.startDate];
      NSDate *monthDate = [calendar dateFromComponents:monthComponents];
      NSDate *dayDate = [calendar dateFromComponents:dayComponents];
      NSMutableDictionary *monthDays = events[monthDate];
      if (!monthDays) {
        monthDays = [NSMutableDictionary dictionary];
        events[monthDate] = monthDays;
      }
      NSMutableArray *dayEvents = monthDays[dayDate];
      if (!dayEvents) {
        dayEvents = [NSMutableArray array];
        monthDays[dayDate] = dayEvents;
      }
      [dayEvents addObject:event];
    }
    _eventsByMonthsAndDays = events;
  }
  return _eventsByMonthsAndDays;
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

- (BOOL)saveEvent:(EKEvent *)event error:(NSError *__autoreleasing *)error
{
  if (![self validateEvent:event error:error]) return NO;
  return [self.store saveEvent:event span:EKSpanThisEvent commit:YES error:error];
}

- (BOOL)validateEvent:(EKEvent *)event error:(NSError *__autoreleasing *)error
{
  static NSString *failureReasonNone = @"";
  NSMutableDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"Event is invalid. ", nil),
                                     NSLocalizedFailureReasonErrorKey: failureReasonNone,
                                     NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please make sure event is filled in. ", nil) }.mutableCopy;
  if (!event.calendar) {
    event.calendar = self.store.defaultCalendarForNewEvents;
  }
  if (!event.endDate ||
      [event.endDate compare:event.startDate] != NSOrderedDescending // Isn't later.
      ) {
    event.endDate = [self dateFromAddingDays:1 toDate:event.startDate];
  }
  if (!event.title.length) {
    userInfo[NSLocalizedFailureReasonErrorKey] = [(NSString *)userInfo[NSLocalizedFailureReasonErrorKey]
                                                  stringByAppendingString:NSLocalizedString(@"Event title is required. ", nil)];
  }
  if (!event.startDate) {
    userInfo[NSLocalizedFailureReasonErrorKey] = [(NSString *)userInfo[NSLocalizedFailureReasonErrorKey]
                                                  stringByAppendingString:NSLocalizedString(@"Event start date is required. ", nil)];
  }
  if (!event.endDate) {
    userInfo[NSLocalizedFailureReasonErrorKey] = [(NSString *)userInfo[NSLocalizedFailureReasonErrorKey]
                                                  stringByAppendingString:NSLocalizedString(@"Event end date is required. ", nil)];
  }
  BOOL isValid = userInfo[NSLocalizedFailureReasonErrorKey] == failureReasonNone;
  if (!isValid) {
    *error = [NSError errorWithDomain:ETErrorDomain
                                 code:ETErrorCodeInvalidObject
                             userInfo:userInfo];
  }
  return isValid;
}

#pragma mark Helpers

- (NSDate *)dateFromAddingDays:(NSInteger)numberOfDays toDate:(NSDate *)date
{
  if (!date) return date;
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *dayComponents = [calendar components:(NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit|
                                                          NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit)
                                                fromDate:date];
  dayComponents.hour = dayComponents.minute = dayComponents.second = 0;
  dayComponents.day += numberOfDays;
  NSDate *newDate = [calendar dateFromComponents:dayComponents];
  return newDate;
}

#pragma mark - Private

- (void)setUp
{
  self.store = [[EKEventStore alloc] init];
  self.operationQueue = [[NSOperationQueue alloc] init];
}

@end
